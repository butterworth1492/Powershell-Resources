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


