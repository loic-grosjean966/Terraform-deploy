# Script de diagnostic temporaire — ne pas committer.
# Interroge l'API v3 de Prism Central pour obtenir le detail complet de l'image
# utilisee par Terraform, notamment son rattachement a un cluster/projet.

$cred = Get-Credential -UserName terraform_user -Message "Identifiants Prism Central"

$body = '{"kind":"image","length":500}'

$r = Invoke-RestMethod -Method Post `
  -Uri "https://172.20.0.200:9440/api/nutanix/v3/images/list" `
  -Credential $cred -Authentication Basic -SkipCertificateCheck `
  -ContentType "application/json" -Body $body

Write-Output "Nombre total d'images visibles par ce compte : $($r.entities.Count)"
Write-Output ""

$img = $r.entities | Where-Object { $_.metadata.uuid -eq "a10febd0-ccca-4b3e-9ba2-52d19d5fa782" }

if ($null -eq $img) {
  Write-Output "AUCUNE IMAGE TROUVEE avec cet UUID pour ce compte."
} else {
  Write-Output "=== Detail complet de l'image ==="
  $img | ConvertTo-Json -Depth 8
}
