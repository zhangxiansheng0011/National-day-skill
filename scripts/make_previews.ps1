param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDir,
    [int]$PreviewWidth = 720,
    [int]$ThumbnailWidth = 480,
    [int]$Quality = 86
)

Add-Type -AssemblyName System.Drawing
$dir = (Resolve-Path -LiteralPath $OutputDir).Path
$previewDir = Join-Path $dir 'preview'
New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

$files = Get-ChildItem -LiteralPath $dir -Filter '*.png' |
    Where-Object { $_.Name -match '^0[1-6]_' } |
    Sort-Object Name
if ($files.Count -ne 6) {
    throw "Expected six template PNG files in $dir, found $($files.Count)."
}

function Save-Jpeg {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path,
        [int]$JpegQuality
    )
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object MimeType -eq 'image/jpeg'
    $parameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
    $parameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
        [System.Drawing.Imaging.Encoder]::Quality,
        [long]$JpegQuality
    )
    $Bitmap.Save($Path, $codec, $parameters)
    $parameters.Dispose()
}

$thumbs = @()
foreach($file in $files) {
    $image = [System.Drawing.Image]::FromFile($file.FullName)
    $height = [int][Math]::Round($image.Height * $PreviewWidth / $image.Width)
    $bitmap = [System.Drawing.Bitmap]::new(
        $PreviewWidth,
        $height,
        [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.DrawImage($image, 0, 0, $PreviewWidth, $height)

    $previewPath = Join-Path $previewDir ($file.BaseName + '_预览.jpg')
    Save-Jpeg $bitmap $previewPath $Quality
    $thumbs += [pscustomobject]@{
        Path = $previewPath
        Title = $file.BaseName
        Width = $PreviewWidth
        Height = $height
    }

    $graphics.Dispose()
    $bitmap.Dispose()
    $image.Dispose()
}

$gap = 24
$columns = 2
$rows = 3
$thumbHeight = [int][Math]::Round($thumbs[0].Height * $ThumbnailWidth / $thumbs[0].Width)
$sheetWidth = $gap + $columns * ($ThumbnailWidth + $gap)
$sheetHeight = $gap + $rows * ($thumbHeight + 72 + $gap)
$sheet = [System.Drawing.Bitmap]::new(
    $sheetWidth,
    $sheetHeight,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)
$graphics = [System.Drawing.Graphics]::FromImage($sheet)
$graphics.Clear([System.Drawing.Color]::FromArgb(244, 240, 232))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$titleFont = [System.Drawing.Font]::new(
    'Microsoft YaHei',
    20,
    [System.Drawing.FontStyle]::Bold,
    [System.Drawing.GraphicsUnit]::Pixel
)
$titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(35, 35, 35))
$center = [System.Drawing.StringFormat]::new()
$center.Alignment = [System.Drawing.StringAlignment]::Center

for($i = 0; $i -lt $thumbs.Count; $i++) {
    $column = $i % $columns
    $row = [int][Math]::Floor($i / $columns)
    $x = $gap + $column * ($ThumbnailWidth + $gap)
    $y = $gap + $row * ($thumbHeight + 72 + $gap)
    $image = [System.Drawing.Image]::FromFile($thumbs[$i].Path)
    $graphics.DrawImage($image, $x, $y, $ThumbnailWidth, $thumbHeight)
    $graphics.DrawString(
        $thumbs[$i].Title,
        $titleFont,
        $titleBrush,
        [System.Drawing.RectangleF]::new($x, $y + $thumbHeight + 12, $ThumbnailWidth, 42),
        $center
    )
    $image.Dispose()
}

$sheetPath = Join-Path $dir '00_六款合集预览.jpg'
Save-Jpeg $sheet $sheetPath ([Math]::Min($Quality + 2, 92))
$center.Dispose()
$titleFont.Dispose()
$titleBrush.Dispose()
$graphics.Dispose()
$sheet.Dispose()

Write-Output "Previews: $previewDir"
Write-Output "Contact sheet: $sheetPath"