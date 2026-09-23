param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,

    [string]$City = '北京',
    [string]$Landmark = '天坛',
    [string]$Date = (Get-Date -Format 'yyyy.MM.dd'),
    [string]$Coordinates = '',
    [string]$Theme = '国庆城市打卡',
    [string]$TravelLabel = '国庆城市漫游',
    [string]$DayProgress = 'DAY 1 / 7',
    [string]$OutputDir = (Join-Path (Get-Location) 'guoqing_templates')
)

Add-Type -AssemblyName System.Drawing
$srcPath = (Resolve-Path -LiteralPath $ImagePath).Path
$outDir = [System.IO.Path]::GetFullPath($OutputDir)
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$yearMatch = [regex]::Match($Date, '\d{4}')
$year = if ($yearMatch.Success) { $yearMatch.Value } else { (Get-Date).Year.ToString() }
$cityLandmark = "$City · $Landmark"
$coordinateText = if ([string]::IsNullOrWhiteSpace($Coordinates)) { "LOCATION · $City" } else { $Coordinates }

$source = [System.Drawing.Image]::FromFile($srcPath)
$W = $source.Width
$H = $source.Height

function New-RoundedPath {
    param([float]$x,[float]$y,[float]$w,[float]$h,[float]$r)
    $p = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Draw-Text {
    param(
        [System.Drawing.Graphics]$g,
        [string]$text,
        [System.Drawing.Font]$font,
        [System.Drawing.Brush]$brush,
        [System.Drawing.RectangleF]$rect,
        [string]$align = 'Center',
        [string]$lineAlign = 'Center'
    )
    $sf = [System.Drawing.StringFormat]::new()
    switch ($align) {
        'Left'  { $sf.Alignment = [System.Drawing.StringAlignment]::Near }
        'Right' { $sf.Alignment = [System.Drawing.StringAlignment]::Far }
        default { $sf.Alignment = [System.Drawing.StringAlignment]::Center }
    }
    switch ($lineAlign) {
        'Top'    { $sf.LineAlignment = [System.Drawing.StringAlignment]::Near }
        'Bottom' { $sf.LineAlignment = [System.Drawing.StringAlignment]::Far }
        default  { $sf.LineAlignment = [System.Drawing.StringAlignment]::Center }
    }
    $sf.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
    $g.DrawString($text, $font, $brush, $rect, $sf)
    $sf.Dispose()
}

function Draw-Star {
    param(
        [System.Drawing.Graphics]$g,
        [float]$cx,[float]$cy,[float]$outer,[float]$inner,
        [System.Drawing.Brush]$brush
    )
    $pts = [System.Drawing.PointF[]]::new(10)
    $start = -90.0
    for($i=0; $i -lt 10; $i++) {
        $r = if($i % 2 -eq 0) { $outer } else { $inner }
        $a = [Math]::PI * ($start + $i * 36.0) / 180.0
        $pts[$i] = [System.Drawing.PointF]::new($cx + [Math]::Cos($a) * $r, $cy + [Math]::Sin($a) * $r)
    }
    $g.FillPolygon($brush, $pts)
}

function New-Canvas {
    param([System.Drawing.Image]$src,[int]$width,[int]$height,[System.Drawing.Color]$bg)
    $bmp = [System.Drawing.Bitmap]::new($width,$height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear($bg)
    $g.DrawImage($src, [System.Drawing.Rectangle]::new(0,0,$width,$height))
    return @{ Bitmap = $bmp; Graphics = $g }
}

function Save-Canvas {
    param([hashtable]$canvas,[string]$path)
    $canvas.Graphics.Dispose()
    $canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Bitmap.Dispose()
}

function Draw-CoverImage {
    param(
        [System.Drawing.Graphics]$g,
        [System.Drawing.Image]$src,
        [System.Drawing.RectangleF]$dest
    )
    $scale = [Math]::Max($dest.Width / $src.Width, $dest.Height / $src.Height)
    $dw = $src.Width * $scale
    $dh = $src.Height * $scale
    $dx = $dest.X - ($dw - $dest.Width) / 2
    $dy = $dest.Y - ($dh - $dest.Height) / 2
    $g.DrawImage($src, [System.Drawing.RectangleF]::new($dx,$dy,$dw,$dh))
}

function New-Font {
    param([string]$family,[float]$size,[System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular)
    return [System.Drawing.Font]::new($family, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

# ---------- 01 红金经典 ----------
$c = New-Canvas $source $W $H ([System.Drawing.Color]::FromArgb(255,20,15,18))
$g = $c.Graphics
$topGrad = [System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.Rectangle]::new(0,0,$W,760), [System.Drawing.Color]::FromArgb(225,90,0,8), [System.Drawing.Color]::FromArgb(0,90,0,8), 90)
$g.FillRectangle($topGrad, [System.Drawing.Rectangle]::new(0,0,$W,760)); $topGrad.Dispose()
$bottomGrad = [System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.Rectangle]::new(0,$H-920,$W,920), [System.Drawing.Color]::FromArgb(0,70,0,8), [System.Drawing.Color]::FromArgb(240,70,0,8), 90)
$g.FillRectangle($bottomGrad, [System.Drawing.Rectangle]::new(0,$H-920,$W,920)); $bottomGrad.Dispose()
$goldPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220,238,190,82), 10)
$goldPen2 = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(150,255,226,140), 4)
$g.DrawRectangle($goldPen, 42,42,$W-84,$H-84)
$g.DrawRectangle($goldPen2, 66,66,$W-132,$H-132); $goldPen.Dispose(); $goldPen2.Dispose()
$starBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245,255,206,91))
Draw-Star $g 126 128 35 14 $starBrush
Draw-Star $g ($W-126) 128 35 14 $starBrush
Draw-Star $g ($W-92) ($H-112) 22 9 $starBrush
$titleFont = New-Font 'STKaiti' 142 ([System.Drawing.FontStyle]::Bold)
$titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,255,222,132))
Draw-Text $g '欢度国庆' $titleFont $titleBrush ([System.Drawing.RectangleF]::new(120,105,$W-240,210))
$subFont = New-Font 'Microsoft YaHei' 31 ([System.Drawing.FontStyle]::Bold)
$subBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(235,255,239,210))
Draw-Text $g "NATIONAL DAY  ·  $year" $subFont $subBrush ([System.Drawing.RectangleF]::new(120,325,$W-240,60))
$cityFont = New-Font 'Microsoft YaHei' 74 ([System.Drawing.FontStyle]::Bold)
Draw-Text $g "$cityLandmark" $cityFont $titleBrush ([System.Drawing.RectangleF]::new(170,$H-400,$W-340,110))
Draw-Text $g "$Date   |   $Theme" $subFont $subBrush ([System.Drawing.RectangleF]::new(170,$H-280,$W-340,60))
$tagPath = New-RoundedPath 170 ($H-185) 255 68 34
$tagBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245,200,22,42))
$g.FillPath($tagBrush,$tagPath)
Draw-Text $g '国庆限定' (New-Font 'Microsoft YaHei' 29 ([System.Drawing.FontStyle]::Bold)) ([System.Drawing.Brushes]::White) ([System.Drawing.RectangleF]::new(170,$H-185,255,68))
$tagPath.Dispose(); $tagBrush.Dispose(); $titleFont.Dispose(); $subFont.Dispose(); $cityFont.Dispose(); $titleBrush.Dispose(); $subBrush.Dispose(); $starBrush.Dispose()
Save-Canvas $c (Join-Path $outDir '01_红金经典.png')

# ---------- 02 城市票根 ----------
$c = New-Canvas $source $W $H ([System.Drawing.Color]::FromArgb(255,244,235,211))
$g = $c.Graphics
$photoRect = [System.Drawing.RectangleF]::new(58,72,$W-116,$H-410)
$clip = New-RoundedPath $photoRect.X $photoRect.Y $photoRect.Width $photoRect.Height 34
$g.SetClip($clip)
$g.Clear([System.Drawing.Color]::FromArgb(255,244,235,211))
Draw-CoverImage $g $source $photoRect
$g.ResetClip()
$stampPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255,187,28,37), 7)
$g.DrawPath($stampPen,$clip); $clip.Dispose(); $stampPen.Dispose()
$paperBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,244,235,211))
$g.FillRectangle($paperBrush, 0, $H-330, $W, 330)
$red = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,185,25,35))
$dark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,49,36,30))
Draw-Text $g $TravelLabel (New-Font 'Microsoft YaHei' 66 ([System.Drawing.FontStyle]::Bold)) $red ([System.Drawing.RectangleF]::new(75,$H-300,$W-150,88)) 'Left' 'Center'
Draw-Text $g 'NATIONAL DAY CITYWALK PASS' (New-Font 'Microsoft YaHei' 24 ([System.Drawing.FontStyle]::Bold)) $dark ([System.Drawing.RectangleF]::new(78,$H-212,$W-156,42)) 'Left' 'Center'
$linePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(150,120,87,65), 3)
$g.DrawLine($linePen,75,$H-148,$W-75,$H-148)
Draw-Text $g "$City  →  $Landmark" (New-Font 'Microsoft YaHei' 40 ([System.Drawing.FontStyle]::Bold)) $dark ([System.Drawing.RectangleF]::new(75,$H-126,$W-330,60)) 'Left' 'Center'
Draw-Text $g "$Date   ·   NO.1001" (New-Font 'Microsoft YaHei' 28) $dark ([System.Drawing.RectangleF]::new(75,$H-70,$W-330,40)) 'Left' 'Center'
$seal = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30,185,25,35))
$g.FillEllipse($seal, $W-255, $H-265, 155, 155)
$sealPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255,185,25,35), 7)
$g.DrawEllipse($sealPen, $W-255, $H-265, 155, 155)
Draw-Text $g '国庆限定' (New-Font 'Microsoft YaHei' 26 ([System.Drawing.FontStyle]::Bold)) $red ([System.Drawing.RectangleF]::new($W-255,$H-225,155,75))
$linePen.Dispose(); $sealPen.Dispose(); $paperBrush.Dispose(); $red.Dispose(); $dark.Dispose(); $seal.Dispose()
Save-Canvas $c (Join-Path $outDir '02_城市票根.png')

# ---------- 03 国风山河 ----------
$c = New-Canvas $source $W $H ([System.Drawing.Color]::FromArgb(255,248,241,218))
$g = $c.Graphics
$washTop = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(150,244,233,200))
$g.FillRectangle($washTop, 0,0,$W,330)
$washBottom = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(185,242,232,201))
$g.FillRectangle($washBottom, 0,$H-610,$W,610)
$mountain1 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(115,31,76,70))
$mountain2 = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(85,12,52,53))
$p1 = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(0,$H-420), [System.Drawing.PointF]::new(270,$H-620),
    [System.Drawing.PointF]::new(500,$H-430), [System.Drawing.PointF]::new(790,$H-680),
    [System.Drawing.PointF]::new(1060,$H-430), [System.Drawing.PointF]::new(1370,$H-660),
    [System.Drawing.PointF]::new(1610,$H-420), [System.Drawing.PointF]::new($W,$H-590),
    [System.Drawing.PointF]::new($W,$H), [System.Drawing.PointF]::new(0,$H)
)
$g.FillPolygon($mountain1,$p1)
$p2 = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(0,$H-240), [System.Drawing.PointF]::new(260,$H-410),
    [System.Drawing.PointF]::new(520,$H-260), [System.Drawing.PointF]::new(800,$H-430),
    [System.Drawing.PointF]::new(1110,$H-250), [System.Drawing.PointF]::new(1430,$H-420),
    [System.Drawing.PointF]::new($W,$H-230), [System.Drawing.PointF]::new($W,$H),
    [System.Drawing.PointF]::new(0,$H)
)
$g.FillPolygon($mountain2,$p2)
$inkPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(230,136,28,31), 8)
$g.DrawRectangle($inkPen, 44,44,$W-88,$H-88); $inkPen.Dispose()
$sealBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245,164,27,30))
$g.FillRectangle($sealBrush, $W-255, 86, 128, 128)
Draw-Text $g "国`n庆" (New-Font 'STKaiti' 39 ([System.Drawing.FontStyle]::Bold)) ([System.Drawing.Brushes]::White) ([System.Drawing.RectangleF]::new($W-255,86,128,128))
$poemFont = New-Font 'STKaiti' 116 ([System.Drawing.FontStyle]::Bold)
$poemBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,132,26,28))
Draw-Text $g '锦绣中华' $poemFont $poemBrush ([System.Drawing.RectangleF]::new(70,80,$W-380,170)) 'Left' 'Center'
$smallFont = New-Font 'Microsoft YaHei' 30 ([System.Drawing.FontStyle]::Bold)
$smallBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,51,61,52))
Draw-Text $g '山河远阔  ·  人间烟火' $smallFont $smallBrush ([System.Drawing.RectangleF]::new(78,245,700,60)) 'Left' 'Center'
Draw-Text $g "$cityLandmark" (New-Font 'STKaiti' 66 ([System.Drawing.FontStyle]::Bold)) $poemBrush ([System.Drawing.RectangleF]::new(75,$H-265,$W-150,90)) 'Left' 'Center'
Draw-Text $g "$Theme  ·  $Date" $smallFont $smallBrush ([System.Drawing.RectangleF]::new(78,$H-175,$W-156,55)) 'Left' 'Center'
$washTop.Dispose(); $washBottom.Dispose(); $mountain1.Dispose(); $mountain2.Dispose(); $sealBrush.Dispose(); $poemFont.Dispose(); $poemBrush.Dispose(); $smallFont.Dispose(); $smallBrush.Dispose()
Save-Canvas $c (Join-Path $outDir '03_国风山河.png')

# ---------- 04 复古号外 ----------
$c = New-Canvas $source $W $H ([System.Drawing.Color]::FromArgb(255,240,224,190))
$g = $c.Graphics
$vintage = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(38,245,224,178))
$g.FillRectangle($vintage,0,0,$W,$H)
$paper = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(225,246,233,200))
$g.FillRectangle($paper,0,0,$W,390)
$g.FillRectangle($paper,0,$H-540,$W,540)
$brownPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(235,74,48,35), 6)
$g.DrawRectangle($brownPen,38,38,$W-76,$H-76); $brownPen.Dispose()
$headFont = New-Font 'SimHei' 118 ([System.Drawing.FontStyle]::Bold)
$headBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,74,48,35))
Draw-Text $g '国庆号外' $headFont $headBrush ([System.Drawing.RectangleF]::new(80,68,$W-160,155))
$enFont = New-Font 'Microsoft YaHei' 25 ([System.Drawing.FontStyle]::Bold)
Draw-Text $g "NATIONAL DAY  SPECIAL  ·  $year" $enFont $headBrush ([System.Drawing.RectangleF]::new(80,205,$W-160,50))
$lineBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,74,48,35))
$g.FillRectangle($lineBrush,78,280,$W-156,5)
Draw-Text $g "${Landmark}夜色，共赴山河" (New-Font 'SimHei' 64 ([System.Drawing.FontStyle]::Bold)) $headBrush ([System.Drawing.RectangleF]::new(78,$H-475,$W-156,96)) 'Left' 'Center'
$bodyBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,88,66,48))
Draw-Text $g "$City · $Landmark  |  $Theme  |  $Date" (New-Font 'Microsoft YaHei' 31 ([System.Drawing.FontStyle]::Bold)) $bodyBrush ([System.Drawing.RectangleF]::new(78,$H-355,$W-156,55)) 'Left' 'Center'
$g.FillRectangle($lineBrush,78,$H-275,$W-156,3)
Draw-Text $g '祈年殿前，月色与灯火同辉。以脚步丈量城市，记下属于国庆的一站。' (New-Font 'Microsoft YaHei' 26) $bodyBrush ([System.Drawing.RectangleF]::new(78,$H-235,$W-156,100)) 'Left' 'Center'
$stampBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(210,174,29,34))
$g.FillEllipse($stampBrush,$W-310,$H-450,190,190)
$stampPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255,174,29,34), 7)
$g.DrawEllipse($stampPen,$W-310,$H-450,190,190)
Draw-Text $g "国庆`n限定" (New-Font 'SimHei' 34 ([System.Drawing.FontStyle]::Bold)) ([System.Drawing.Brushes]::White) ([System.Drawing.RectangleF]::new($W-310,$H-420,190,130))
$vintage.Dispose(); $paper.Dispose(); $headFont.Dispose(); $headBrush.Dispose(); $enFont.Dispose(); $lineBrush.Dispose(); $bodyBrush.Dispose(); $stampBrush.Dispose(); $stampPen.Dispose()
Save-Canvas $c (Join-Path $outDir '04_复古号外.png')

# ---------- 05 夜色烟花 ----------
$c = New-Canvas $source $W $H ([System.Drawing.Color]::FromArgb(255,8,18,40))
$g = $c.Graphics
$night = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(38,4,14,38))
$g.FillRectangle($night,0,0,$W,$H)
$goldPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(230,242,190,65), 8)
$g.DrawRectangle($goldPen,40,40,$W-80,$H-80)
$innerPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(120,255,223,133), 3)
$g.DrawRectangle($innerPen,67,67,$W-134,$H-134)
$fireBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180,255,215,116))
$firePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(155,255,215,116), 4)
$bursts = @(@(210,260,150),@(1710,420,185),@(1500,760,120))
foreach($b in $bursts){
  $cx=$b[0]; $cy=$b[1]; $rr=$b[2]
  for($i=0; $i -lt 18; $i++){
    $a=[Math]::PI*2*$i/18
    $x2=$cx+[Math]::Cos($a)*$rr; $y2=$cy+[Math]::Sin($a)*$rr
    $g.DrawLine($firePen,$cx,$cy,$x2,$y2)
    $g.FillEllipse($fireBrush,$x2-6,$y2-6,12,12)
  }
}
$starBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220,255,225,140))
Draw-Star $g 150 600 28 11 $starBrush
Draw-Star $g ($W-155) 980 34 13 $starBrush
$titleFont = New-Font 'STKaiti' 150 ([System.Drawing.FontStyle]::Bold)
$titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,255,217,105))
Draw-Text $g '盛世华诞' $titleFont $titleBrush ([System.Drawing.RectangleF]::new(130,118,$W-260,200))
Draw-Text $g "NATIONAL DAY  ·  $year" (New-Font 'Microsoft YaHei' 32 ([System.Drawing.FontStyle]::Bold)) ([System.Drawing.Brushes]::White) ([System.Drawing.RectangleF]::new(130,338,$W-260,55))
Draw-Text $g "$City·$Landmark  |  夜色打卡" (New-Font 'Microsoft YaHei' 53 ([System.Drawing.FontStyle]::Bold)) ([System.Drawing.Brushes]::White) ([System.Drawing.RectangleF]::new(155,$H-390,$W-310,80))
Draw-Text $g "$Date  ·  $TravelLabel" (New-Font 'Microsoft YaHei' 30) $titleBrush ([System.Drawing.RectangleF]::new(155,$H-280,$W-310,50))
$night.Dispose(); $goldPen.Dispose(); $innerPen.Dispose(); $fireBrush.Dispose(); $firePen.Dispose(); $starBrush.Dispose(); $titleFont.Dispose(); $titleBrush.Dispose()
Save-Canvas $c (Join-Path $outDir '05_夜色烟花.png')

# ---------- 06 极简假期 ----------
$c = New-Canvas $source $W $H ([System.Drawing.Color]::FromArgb(255,235,236,232))
$g = $c.Graphics
$topBand = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(220,20,20,22))
$g.FillRectangle($topBand,0,0,$W,210)
$bottomBand = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(235,20,20,22))
$g.FillRectangle($bottomBand,0,$H-600,$W,600)
$red = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,204,27,42))
$white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,245,242,233))
$gold = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,232,190,86))
Draw-Text $g "$year  国庆" (New-Font 'Microsoft YaHei' 50 ([System.Drawing.FontStyle]::Bold)) $white ([System.Drawing.RectangleF]::new(70,54,420,100)) 'Left' 'Center'
Draw-Text $g '10.01' (New-Font 'Microsoft YaHei' 42 ([System.Drawing.FontStyle]::Bold)) $white ([System.Drawing.RectangleF]::new($W-300,54,230,100)) 'Right' 'Center'
$g.FillRectangle($red,70,146,320,8)
Draw-Text $g $Theme (New-Font 'Microsoft YaHei' 92 ([System.Drawing.FontStyle]::Bold)) $white ([System.Drawing.RectangleF]::new(80,$H-525,$W-160,140)) 'Left' 'Center'
Draw-Text $g "$cityLandmark" (New-Font 'Microsoft YaHei' 56 ([System.Drawing.FontStyle]::Bold)) $gold ([System.Drawing.RectangleF]::new(80,$H-375,$W-160,80)) 'Left' 'Center'
Draw-Text $g $coordinateText (New-Font 'Microsoft YaHei' 28) $white ([System.Drawing.RectangleF]::new(80,$H-282,$W-160,50)) 'Left' 'Center'
$barBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180,255,255,255))
$g.FillRectangle($barBg,80,$H-190,$W-160,22)
$g.FillRectangle($red,80,$H-190,($W-160)*0.14,22)
Draw-Text $g "假期进度  $DayProgress" (New-Font 'Microsoft YaHei' 28 ([System.Drawing.FontStyle]::Bold)) $white ([System.Drawing.RectangleF]::new(80,$H-140,$W-160,45)) 'Left' 'Center'
$topBand.Dispose(); $bottomBand.Dispose(); $red.Dispose(); $white.Dispose(); $gold.Dispose(); $barBg.Dispose()
Save-Canvas $c (Join-Path $outDir '06_极简假期.png')

$source.Dispose()
Write-Output "Generated files:"
Get-ChildItem -LiteralPath $outDir -Filter '*.png' | Select-Object Name,Length




