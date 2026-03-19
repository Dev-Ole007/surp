$ErrorActionPreference = "Stop"
$root = (Get-Location).Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:5500/")
$listener.Start()
Write-Output "Servidor iniciado em http://localhost:5500/"

function Get-ContentType([string]$path) {
  switch ([IO.Path]::GetExtension($path).ToLowerInvariant()) {
    ".html" { "text/html; charset=utf-8" }
    ".css"  { "text/css; charset=utf-8" }
    ".js"   { "application/javascript; charset=utf-8" }
    ".json" { "application/json; charset=utf-8" }
    ".jpg"  { "image/jpeg" }
    ".jpeg" { "image/jpeg" }
    ".png"  { "image/png" }
    ".gif"  { "image/gif" }
    ".svg"  { "image/svg+xml" }
    ".mp3"  { "audio/mpeg" }
    ".mp4"  { "video/mp4" }
    ".wav"  { "audio/wav" }
    default  { "application/octet-stream" }
  }
}

while ($listener.IsListening) {
  $context = $listener.GetContext()
  try {
    $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($relative)) { $relative = "index.html" }
    $filePath = Join-Path $root $relative

    if (Test-Path $filePath -PathType Leaf) {
      $bytes = [IO.File]::ReadAllBytes($filePath)
      $context.Response.StatusCode = 200
      $context.Response.ContentType = Get-ContentType $filePath
      $context.Response.ContentLength64 = $bytes.Length
      $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $notFound = [Text.Encoding]::UTF8.GetBytes("404 - Arquivo nao encontrado")
      $context.Response.StatusCode = 404
      $context.Response.ContentType = "text/plain; charset=utf-8"
      $context.Response.ContentLength64 = $notFound.Length
      $context.Response.OutputStream.Write($notFound, 0, $notFound.Length)
    }
  } catch {
    $err = [Text.Encoding]::UTF8.GetBytes("500 - Erro interno")
    $context.Response.StatusCode = 500
    $context.Response.ContentType = "text/plain; charset=utf-8"
    $context.Response.ContentLength64 = $err.Length
    $context.Response.OutputStream.Write($err, 0, $err.Length)
  } finally {
    $context.Response.OutputStream.Close()
  }
}
