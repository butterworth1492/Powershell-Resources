<#
 Copyright (c) 2014, butterworth1492
 All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

# Notes:
#   powershell -Command "& { $code=Get-Content <path to script>|Out-String; Invoke-Expression $code; Invoke-SQL -SqlCommand 'select * from information_schema.tables' -ConnectionString 'Data Source=<IP>;Initial Catalog=<db>;User ID=<user>;Password=<password>’ }"
function Invoke-SQL 
  {
    param
      (
        [string] $connectionString = $(throw "Please specify a connection string."),
        [string] $sqlCommand = $(throw "Please specify a SQL query.")
      )
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $connection.Close()
    $dataSet.Tables
  } # end Invoke-SQL


# Notes:
#   powershell -Command "& { Http-Request -URI '<URL>'}"
# SOAP Example:
#   1) Create giant SOAP-request string
#   2) Base-64-encode the string
#   3) powershell -Command "& { $code=Get-Content <path to script>|Out-String; Invoke-Expression $code; Http-Request -Uri '<Full SOAP resource URL>' -Soap '<base64-encode string>';}"
function Http-Request
  {
    param
      (
        [string] $uri = $(throw "Please specify a URI."),
        [string] $soap = $null
      )
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};
    $request = [System.Net.WebRequest]::Create($uri);
    [byte[]]$bytes = $null;
    if ($soap)
      {
        $soap = [System.Text.Encoding]::ASCII.GetSTring([System.Convert]::FromBase64String($soap));
        $soap = $soap.replace("`n","").replace("`r","");
        $request.method = "POST";
        $request.ContentType = "application/soap+xml";
        $encoder = [System.Text.Encoding]::GetEncoding("UTF-8");
        $bytes = $encoder.GetBytes($soap);
        $request.ContentLength = $bytes.Length;
        Write-Host "Soap envelope: $($soap)";
      }
    try
      {
        if ($soap)
          {
            $request_string = $request.GetRequestStream();
            $request_string.Write($bytes,0,$bytes.Length);
          }
        $response = $request.GetResponse();
        $response_stream = $response.GetResponseStream();
        $stream_reader = new-object System.IO.StreamReader $response_stream;
        $result = $stream_reader.ReadToEnd();
        write-host "$($result)";
      }
    finally
      {
        if ( $null -ne $response_stream ) { $response_stream.Dispose() }
        if ( $null -ne $stream_reader ) { $stream_reader.Dispose() }
        if ( $null -ne $result ) { $stream_reader.Dispose() }
      }
  } # end Http-Request


# Notes:
#   powershell -Command "& { $code=Get-Content c:\Users\cave\Desktop\powerpack.ps1 | Out-String; Invoke-Expression $code; Port-Query -Target 192.168.25.110 -Port 80 }"
# Multiple ports/hosts w/ explicit timeout:
#   powershell -Command "& { $code=Get-Content c:\Users\cave\Desktop\powerpack.ps1 | Out-String; Invoke-Expression $code; Port-Query -MinDelay 10 -MaxDelay 15 -Target '192.168.25.110 192.168.25.152' -Port '80 443 8080 8443 21 22 23 25 110' -Timeout 500 }"
function Port-Query
  {
    param
      (
        [string] $target = $(throw "Please specify a target."),
        [string] $port = $(throw "Please specify a port."),
        [string] $timeout = 3000,                                # milliseconds
        [string] $mindelay = 5,                                  # seconds
        [string] $maxdelay = 30                                  # seconds
      )
  if ($target -match " ")
    { $targets = $target.split(" ") }
  else
    {
      $targets = New-Object Object[] 1;
      $targets[0] = $target
    }
  if ($port -match " ")
    { $ports = $port.split(" ") }
  else
    {
      $ports = New-Object Object[] 1;
      $ports[0] = $port;
    }
  foreach ($t in $targets)
    {
      foreach ($p in $ports)
        {
          $delay = $(Get-Random -minimum $mindelay -maximum $maxdelay)
          Start-Sleep -s $delay
          $client = New-Object System.Net.Sockets.TcpClient;
          $asyncresult = $client.BeginConnect($t, $p, $null, $null);
          $wait = $asyncresult.AsyncWaitHandle.WaitOne($timeout);
          write-Host -NoNewline "[$delay] $($t):$($p) (TCP) -> ";
          if ($wait)
            {
              try
                { $client.EndConnect($asyncresult) }
              catch
                {}
              finally
                { Write-Host ">> OPEN <<" }
            }
          else
            { Write-Host "[$($timeout)ms]"; }
        }
    }
  } # end Port-Query
