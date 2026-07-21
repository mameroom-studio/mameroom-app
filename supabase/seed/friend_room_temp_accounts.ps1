param([ValidateSet('create','cleanup')][string]$Action='create')
$ErrorActionPreference='Stop'
$projectRef='zglfjvnjnopilhikkxum'
$baseUser='1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e'
$baseUrl="https://$projectRef.supabase.co"
$emails=1..5 | ForEach-Object { 'mameroom.temp{0:d2}@example.com' -f $_ }
$keyResult=supabase projects api-keys --project-ref $projectRef --reveal --output-format json | ConvertFrom-Json
$key=($keyResult.keys | Where-Object { $_.id -eq 'service_role' }).api_key
if (-not $key) { throw 'service_role key unavailable from Supabase CLI' }
$headers=@{apikey=$key;Authorization="Bearer $key"}
function Get-TestUsers {
  $result=Invoke-RestMethod -Method Get -Uri "$baseUrl/auth/v1/admin/users?page=1&per_page=1000" -Headers $headers
  @($result.users | Where-Object { $emails -contains $_.email -or $_.app_metadata.test_group -eq 'friend_room_mvp' })
}
if ($Action -eq 'cleanup') {
  $targets=Get-TestUsers
  foreach($u in $targets) {
    if (($emails -notcontains $u.email) -or $u.app_metadata.is_test_account -ne $true -or $u.app_metadata.test_group -ne 'friend_room_mvp') { throw "cleanup guard rejected $($u.email)" }
  }
  if ($targets.Count -eq 0) { Write-Output 'No friend_room_mvp temp users found.'; exit 0 }
  $ids=@($targets | ForEach-Object { "'$(param([ValidateSet('create','cleanup')][string]$Action='create')
$ErrorActionPreference='Stop'
$projectRef='zglfjvnjnopilhikkxum'
$baseUser='1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e'
$baseUrl="https://$projectRef.supabase.co"
$emails=1..5 | ForEach-Object { 'mameroom.temp{0:d2}@example.com' -f $_ }
$keyResult=supabase projects api-keys --project-ref $projectRef --reveal --output-format json | ConvertFrom-Json
$key=($keyResult.keys | Where-Object { $_.id -eq 'service_role' }).api_key
if (-not $key) { throw 'service_role key unavailable from Supabase CLI' }
$headers=@{apikey=$key;Authorization="Bearer $key"}
function Get-TestUsers {
  $result=Invoke-RestMethod -Method Get -Uri "$baseUrl/auth/v1/admin/users?page=1&per_page=1000" -Headers $headers
  @($result.users | Where-Object { $emails -contains $_.email -or $_.app_metadata.test_group -eq 'friend_room_mvp' })
}
if ($Action -eq 'cleanup') {
  $targets=Get-TestUsers
  foreach($u in $targets) {
    if (($emails -notcontains $u.email) -or $u.app_metadata.is_test_account -ne $true -or $u.app_metadata.test_group -ne 'friend_room_mvp') { throw "cleanup guard rejected $($u.email)" }
  }
  foreach($u in $targets) { Invoke-RestMethod -Method Delete -Uri "$baseUrl/auth/v1/admin/users/$($u.id)" -Headers $headers | Out-Null }
  Write-Output "Deleted $($targets.Count) friend_room_mvp auth users; FK cascades remove only their profiles, friendships, inventory and layouts."
  exit 0
}
$existing=Get-TestUsers
if ($existing.Count -ne 0) { throw "Temp collision: $($existing.Count) matching auth users already exist. Run cleanup or inspect first." }
$created=@()
try {
  for($i=1;$i -le 5;$i++) {
    $email=$emails[$i-1]
    $bytes=New-Object byte[] 24; $rng=[Security.Cryptography.RandomNumberGenerator]::Create(); $rng.GetBytes($bytes); $rng.Dispose(); $password=[Convert]::ToBase64String($bytes)+'aA1!'
    $body=@{email=$email;password=$password;email_confirm=$true;app_metadata=@{is_test_account=$true;test_group='friend_room_mvp';test_sequence=$i};user_metadata=@{nickname=('mameroom.temp{0:d2}' -f $i)}} | ConvertTo-Json -Depth 5
    $u=Invoke-RestMethod -Method Post -Uri "$baseUrl/auth/v1/admin/users" -Headers $headers -ContentType 'application/json' -Body $body
    $created += $u
  }
  $profileValues=@(); $friendValues=@(); $inventoryValues=@(); $layoutValues=@()
  $items=@(
    @('640b9a8d-aa79-4610-9cbe-60b4ae284b75',.30,.73),
    @('8b5df97d-7c7f-4fa1-8dda-c0313048921b',.52,.66),
    @('938de710-21c0-4ace-9810-b04ab855664f',.20,.56),
    @('dee72594-995d-44cf-9849-4d6895179236',.80,.62),
    @('cfbc04c6-6057-4c94-bdf7-7cc291be71ab',.52,.84),
    @('64fd0596-032c-4238-8395-fe3e76f16858',.78,.24)
  )
  for($i=1;$i -le 5;$i++) {
    $id=$created[$i-1].id
    $profileValues += "('$id','mameroom.temp{0:d2}','TEMPFR{0:d2}','temp_avatar_{0:d2}',{1},'Friend Room QA Temp {0:d2}','friends','active')" -f $i,(10+$i)
    $friendValues += "(least('$baseUser'::uuid,'$id'::uuid),greatest('$baseUser'::uuid,'$id'::uuid))"
    $count=$i+1
    for($j=0;$j -lt $count;$j++) {
      $item=$items[$j]; $inventoryValues += "('$id','$($item[0])')"
      $x=[double]$item[1] + (($i-3)*.015); $y=[double]$item[2] - (($i-3)*.01)
      $layoutValues += "('$id','$($item[0])',$($x.ToString([Globalization.CultureInfo]::InvariantCulture)),$($y.ToString([Globalization.CultureInfo]::InvariantCulture)))"
    }
  }
  $sql="begin; update public.profiles p set nickname=v.nickname,friend_code=v.friend_code,avatar_key=v.avatar_key,level=v.level,status_message=v.status_message,room_visibility=v.room_visibility,account_status=v.account_status from (values $($profileValues -join ',')) as v(id,nickname,friend_code,avatar_key,level,status_message,room_visibility,account_status) where p.id=v.id::uuid; insert into public.friendships(user_low_id,user_high_id) values $($friendValues -join ','); insert into public.user_items(user_id,item_id) values $($inventoryValues -join ','); insert into public.user_room_layouts(user_id,item_id,position_x,position_y) values $($layoutValues -join ','); commit;"
  [IO.File]::WriteAllText('supabase\.temp\friend_room_seed.sql',$sql,[Text.UTF8Encoding]::new($false));
  $supabasePath=(Get-Command supabase).Source
  $proc=Start-Process -FilePath $supabasePath -ArgumentList @('db','query','--linked','--output-format','json','--file','supabase\.temp\friend_room_seed.sql') -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput 'supabase\.temp\friend_room_seed.out' -RedirectStandardError 'supabase\.temp\friend_room_seed.err'
  $result=[IO.File]::ReadAllText('supabase\.temp\friend_room_seed.out')
  if($proc.ExitCode -ne 0){ Write-Output ([IO.File]::ReadAllText('supabase\.temp\friend_room_seed.err')); throw 'DB seed transaction failed' }
  Write-Output $result
  Write-Output "Created 5 auth users, 5 profiles, 5 friendships, 20 inventory rows, 20 layouts."
} catch {
  foreach($u in $created) { try { Invoke-RestMethod -Method Delete -Uri "$baseUrl/auth/v1/admin/users/$($u.id)" -Headers $headers | Out-Null } catch {} }
  throw
}
.id)'::uuid" })
  $idList=$ids -join ','
  $cleanupSql="begin; delete from public.friendships where user_low_id in ($idList) or user_high_id in ($idList); delete from public.user_room_layouts where user_id in ($idList); delete from public.user_items where user_id in ($idList); delete from public.profiles where id in ($idList); commit;"
  [IO.File]::WriteAllText('supabase\.temp\friend_room_cleanup.sql',$cleanupSql,[Text.UTF8Encoding]::new($false))
  $supabasePath=(Get-Command supabase).Source
  $proc=Start-Process -FilePath $supabasePath -ArgumentList @('db','query','--linked','--output-format','json','--file','supabase\.temp\friend_room_cleanup.sql') -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput 'supabase\.temp\friend_room_cleanup.out' -RedirectStandardError 'supabase\.temp\friend_room_cleanup.err'
  if($proc.ExitCode -ne 0){ Write-Output ([IO.File]::ReadAllText('supabase\.temp\friend_room_cleanup.err')); throw 'DB cleanup transaction failed; auth users were retained' }
  foreach($u in $targets) { Invoke-RestMethod -Method Delete -Uri "$baseUrl/auth/v1/admin/users/$($u.id)" -Headers $headers | Out-Null }
  Write-Output "Deleted $($targets.Count) guarded friend_room_mvp users and their profiles, friendships, inventory and layouts."
  exit 0
}
$existing=Get-TestUsers
if ($existing.Count -ne 0) { throw "Temp collision: $($existing.Count) matching auth users already exist. Run cleanup or inspect first." }
$created=@()
try {
  for($i=1;$i -le 5;$i++) {
    $email=$emails[$i-1]
    $bytes=New-Object byte[] 24; $rng=[Security.Cryptography.RandomNumberGenerator]::Create(); $rng.GetBytes($bytes); $rng.Dispose(); $password=[Convert]::ToBase64String($bytes)+'aA1!'
    $body=@{email=$email;password=$password;email_confirm=$true;app_metadata=@{is_test_account=$true;test_group='friend_room_mvp';test_sequence=$i};user_metadata=@{nickname=('mameroom.temp{0:d2}' -f $i)}} | ConvertTo-Json -Depth 5
    $u=Invoke-RestMethod -Method Post -Uri "$baseUrl/auth/v1/admin/users" -Headers $headers -ContentType 'application/json' -Body $body
    $created += $u
  }
  $profileValues=@(); $friendValues=@(); $inventoryValues=@(); $layoutValues=@()
  $items=@(
    @('640b9a8d-aa79-4610-9cbe-60b4ae284b75',.30,.73),
    @('8b5df97d-7c7f-4fa1-8dda-c0313048921b',.52,.66),
    @('938de710-21c0-4ace-9810-b04ab855664f',.20,.56),
    @('dee72594-995d-44cf-9849-4d6895179236',.80,.62),
    @('cfbc04c6-6057-4c94-bdf7-7cc291be71ab',.52,.84),
    @('64fd0596-032c-4238-8395-fe3e76f16858',.78,.24)
  )
  for($i=1;$i -le 5;$i++) {
    $id=$created[$i-1].id
    $profileValues += "('$id','mameroom.temp{0:d2}','TEMPFR{0:d2}','temp_avatar_{0:d2}',{1},'Friend Room QA Temp {0:d2}','friends','active')" -f $i,(10+$i)
    $friendValues += "(least('$baseUser'::uuid,'$id'::uuid),greatest('$baseUser'::uuid,'$id'::uuid))"
    $count=$i+1
    for($j=0;$j -lt $count;$j++) {
      $item=$items[$j]; $inventoryValues += "('$id','$($item[0])')"
      $x=[double]$item[1] + (($i-3)*.015); $y=[double]$item[2] - (($i-3)*.01)
      $layoutValues += "('$id','$($item[0])',$($x.ToString([Globalization.CultureInfo]::InvariantCulture)),$($y.ToString([Globalization.CultureInfo]::InvariantCulture)))"
    }
  }
  $sql="begin; update public.profiles p set nickname=v.nickname,friend_code=v.friend_code,avatar_key=v.avatar_key,level=v.level,status_message=v.status_message,room_visibility=v.room_visibility,account_status=v.account_status from (values $($profileValues -join ',')) as v(id,nickname,friend_code,avatar_key,level,status_message,room_visibility,account_status) where p.id=v.id::uuid; insert into public.friendships(user_low_id,user_high_id) values $($friendValues -join ','); insert into public.user_items(user_id,item_id) values $($inventoryValues -join ','); insert into public.user_room_layouts(user_id,item_id,position_x,position_y) values $($layoutValues -join ','); commit;"
  [IO.File]::WriteAllText('supabase\.temp\friend_room_seed.sql',$sql,[Text.UTF8Encoding]::new($false));
  $supabasePath=(Get-Command supabase).Source
  $proc=Start-Process -FilePath $supabasePath -ArgumentList @('db','query','--linked','--output-format','json','--file','supabase\.temp\friend_room_seed.sql') -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput 'supabase\.temp\friend_room_seed.out' -RedirectStandardError 'supabase\.temp\friend_room_seed.err'
  $result=[IO.File]::ReadAllText('supabase\.temp\friend_room_seed.out')
  if($proc.ExitCode -ne 0){ Write-Output ([IO.File]::ReadAllText('supabase\.temp\friend_room_seed.err')); throw 'DB seed transaction failed' }
  Write-Output $result
  Write-Output "Created 5 auth users, 5 profiles, 5 friendships, 20 inventory rows, 20 layouts."
} catch {
  foreach($u in $created) { try { Invoke-RestMethod -Method Delete -Uri "$baseUrl/auth/v1/admin/users/$($u.id)" -Headers $headers | Out-Null } catch {} }
  throw
}
