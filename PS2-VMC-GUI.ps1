

$Error.Clear()

Add-Type -AssemblyName System.Windows.Forms

$FormObject                = [System.Windows.Forms.Form]
$ButtonObject              = [System.Windows.Forms.Button]
$TextBoxObject             = [System.Windows.Forms.TextBox]

function Write-Form {
    param (
        $WriteFormMessage,
        $WriteFormTitle
    )
    $WriteForm = New-Object $FormObject
    $WriteForm.Text = $WriteFormTitle
    $WriteForm.AutoSize = $true
    $WriteForm.FormBorderStyle = "FixedSingle"
    $WriteForm.Padding = New-Object System.Windows.Forms.Padding( 20 )
    $WriteForm.Font = New-Object System.Drawing.Font( "Segoe UI" , 12 )

    $WriteFormTextBox = New-Object $TextBoxObject
    $WriteFormTextBox.Text = $WriteFormMessage
    $WriteFormTextBox.ReadOnly = $true
    $WriteFormTextBox.Multiline = $true
    $WriteFormTextBox.TabStop = $false
    $WriteFormTextBox.ScrollBars = "Vertical"
    $WriteFormTextBox.ClientSize = "800 , 400"
    $WriteFormTextBox.Location = New-Object System.Drawing.Point( 20 , 10 )
    $WriteForm.Controls.Add( $WriteFormTextBox )

    $WriteFormButtonCancel = New-Object $ButtonObject
    $WriteFormButtonCancel.Text = "Cancel"
    $WriteFormButtonCancel.AutoSize = $true
    $WriteFormButtonCancel.Location = New-Object System.Drawing.Point( 620 , 430 )
    $WriteForm.CancelButton = $WriteFormButtonCancel
    $WriteForm.Controls.Add( $WriteFormButtonCancel )

    $WriteFormButton = New-Object $ButtonObject
    $WriteFormButton.Text = "OK"
    $WriteFormButton.AutoSize = $true
    $WriteFormButton.Location = New-Object System.Drawing.Point( 720 , 430 )
    $WriteFormButton.DialogResult = "OK"
    $WriteForm.AcceptButton = $WriteFormButton
    $WriteForm.Controls.Add( $WriteFormButton )

    return $WriteForm.ShowDialog()
}
Write-Host "The Online version has been deprecated.
Please download the repository and use PS2-VMC-GUI-Offline.ps1`r`n
https://github.com/MegaBitmap/PS2-VMC-GUI"
Write-Form "The Online version has been deprecated.
Please download the repository and use PS2-VMC-GUI-Offline.ps1`r`n
https://github.com/MegaBitmap/PS2-VMC-GUI" "Online Version Deprecated."

