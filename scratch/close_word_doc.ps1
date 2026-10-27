try {
    $word = [System.Runtime.InteropServices.Marshal]::GetActiveObject("Word.Application")
    foreach ($doc in $word.Documents) {
        Write-Host "Found in Word: " $doc.FullName
        if ($doc.FullName -like "*Task1_Logical_View*") {
            $doc.Close([ref]$false)
            Write-Host "Closed Task1_Logical_View in Word successfully!"
        }
    }
} catch {
    Write-Host "COM error: " $_.Exception.Message
}
