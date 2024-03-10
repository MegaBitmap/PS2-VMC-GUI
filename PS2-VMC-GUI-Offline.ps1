<#
.Synopsis
   PlayStation 2 Virtual Memory Card Graphical User Interface.
.DESCRIPTION
   PS2-VMC-GUI uses ps2vmc-tool by bucanero to manage saves on a VMC file.
#>
$Error.Clear()

Add-Type -AssemblyName System.Windows.Forms

$FormObject                = [System.Windows.Forms.Form]
$LabelObject               = [System.Windows.Forms.Label]
$ButtonObject              = [System.Windows.Forms.Button]
$TextBoxObject             = [System.Windows.Forms.TextBox]
$FolderBrowserDialogObject = [System.Windows.Forms.FolderBrowserDialog]
$OpenFileDialogObject      = [System.Windows.Forms.OpenFileDialog]
$SaveFileDialogObject      = [System.Windows.Forms.SaveFileDialog]
$ListViewObject            = [System.Windows.Forms.ListView]
$ListViewItem              = [System.Windows.Forms.ListViewItem]
$PictureBoxObject          = [System.Windows.Forms.PictureBox]
$CheckBoxObject            = [System.Windows.Forms.CheckBox]

$JIS   = [System.Text.Encoding]::GetEncoding("Shift-JIS")
$W1252 = [System.Text.Encoding]::GetEncoding("Windows-1252")

$ScriptPath      = Get-Location
$TempDir         = "$env:TEMP\ps2-vmc-gui"
$SetupFilesZip   = "$ScriptPath\Setupfiles.zip"
$License         = "$ScriptPath\LICENSE.txt"
$VMCTool         = "$TempDir\ps2vmc-tool.exe"
$BlankVMCZip     = "$TempDir\BlankVMC.zip"
$BoxArtDatabase  = "https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/"
# $ScriptRepo      = "https://raw.githubusercontent.com/MegaBitmap/PS2-VMC-GUI/master"
# $SetupFilesURI   = "$ScriptRepo/SetupFiles.zip"
# $LicenseURI      = "$ScriptRepo/LICENSE.txt"

$DefaultDir = New-Object $LabelObject
$DefaultDir.Text = "$env:USERPROFILE\Desktop"

$WelcomeMessage = "Please Click Open File and select a VMC file."
$UnreadableMessage = "no PS2 Memory Card detected"

function Get-SaveName {
    param (
        $IconSysFile
    )
    # Convert Shift JIS to ASCII
    $IconSysRaw = $W1252.GetBytes( ( Get-Content $IconSysFile ) )

    $SaveName = $JIS.GetString( $IconSysRaw[192..259] )   

    for ( ( $ASCIIIndex = 0x21 ),( $UnicodeIndex = 0xFF01 ); $ASCIIIndex -lt 0x7E; $ASCIIIndex++ , $UnicodeIndex++ ) {

        $SaveName = $SaveName -creplace [char]$UnicodeIndex,[char]$ASCIIIndex -replace "$( [char]0x0000 )|$( [char]0xF8F1 )" -replace [char]0x3000," "
    }
    return $SaveName
}
function Find-Error {
    if ( $Error ) {
        Write-Form "`r`nAn error has occured:`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
        return $true
    }
}
function Set-File {
    param (
        $FileFilter
    )
    $SetFileDialog = New-Object $OpenFileDialogObject
    $SetFileDialog.InitialDirectory = $DefaultDir.Text
    $SetFileDialog.Filter = $FileFilter

    $Result = $SetFileDialog.ShowDialog()
    if ( $Result -notmatch "Cancel" ) {

        $DefaultDir.Text = ( Get-Item $SetFileDialog.FileName ).Directory

        return $SetFileDialog.FileName
    }
}
function Set-SaveFile {
    param (
        $Default
    )
    $SaveFileDialog = New-Object $SaveFileDialogObject
    $SaveFileDialog.InitialDirectory = $DefaultDir.Text
    $SaveFileDialog.Filter = "LaunchELF (.psu)|*.psu"
    $SaveFileDialog.FileName = $Default

    $Result = $SaveFileDialog.ShowDialog()
    if ( $Result -notmatch "Cancel" ) {
        
        return $SaveFileDialog.FileName
    }
}
function Set-VMCFile {
    param (
        $Default
    )
    $SaveFileDialog = New-Object $SaveFileDialogObject
    $SaveFileDialog.InitialDirectory = $DefaultDir.Text
    $SaveFileDialog.Filter = "VMC File (*.bin)|*.bin"
    $SaveFileDialog.FileName = $Default

    $Result = $SaveFileDialog.ShowDialog()
    if ( $Result -notmatch "Cancel" ) {
        return $SaveFileDialog.FileName
    }
}
function Set-Folder {
    param (
        $Default
    )
    $SetFolderDialog = New-Object $FolderBrowserDialogObject

    $Result = $SetFolderDialog.ShowDialog()
    if ( $Result ) {
        return $SetFolderDialog.SelectedPath
    }
    else {
        return $Default
    }
}
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
function Get-VMCList {
    param (
        $VMCFile
    )
    $RootDirTable = & $VMCTool $VMCFile --list /

    foreach ($RootDirLine in $RootDirTable) {

        if ( $RootDirLine -notmatch 'PS2VMC-TOOL v|----------|"."|".."' ) {

            $SaveInfo = $RootDirLine -split " / "

            $FolderName = $SaveInfo[0]
            $Type = $SaveInfo[1]
            $Size = $SaveInfo[2]
            $Time = $SaveInfo[4]

            if ( $Type -match "<file>" ) {
                Write-Host "ERROR: You must manually delete all files from root as this GUI does not support them"
                return
            }
            $AllSize = [int]$Size

            $SaveDirTable = & $VMCTool $VMCFile --list $FolderName

            foreach ( $SaveDirLine in $SaveDirTable ) {

                if ( $SaveDirLine -notmatch 'PS2VMC-TOOL v|----------|"."|".."' ) {

                    $SaveFileInfo = $SaveDirLine -split " / "

                    $SaveFileType = $SaveFileInfo[1]
                    $SaveFileSize = $SaveFileInfo[2]

                    if ( $SaveFileType -match "<dir>" ) {
                        Write-Host "ERROR: You must manually delete all subfolders as this GUI does not support them"
                        return
                    }
                    $AllSize += [int]$SaveFileSize
                }
            }
            if ( $SaveDirTable -match "icon.sys" ) {

                $ExtractIconInfo = & $VMCTool $VMCFile --extract-file $FolderName/icon.sys $TempDir\icon.sys

                if ( $ExtractIconInfo -match "Error" ) {

                    $FormExtract = $null
                    foreach ( $Line in $ExtractIconInfo ) {
                        $FormExtract += "$Line`r`n"
                    }
                    Write-Form "`r`nAn error has occured:`r`n`r`nThere was an error exporting icon.sys`r`n`r`n$FormExtract`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                    $FriendlyName = $null
                }
                else {
                    foreach ( $Line in $ExtractIconInfo ) {

                        if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                            Write-Host $Line
                        }
                    }
                    $FriendlyName = Get-SaveName $TempDir\icon.sys
                }
            }
            else {
                $FriendlyName = $null
            }
            $RoundedSize = [string][math]::truncate( $AllSize / 1024 )+"KB"

            $Date = $Time -replace '-.*'

            $NewItem = New-Object $ListViewItem
            $NewItem.Name = $FolderName
            $NewItem.Text = $FolderName

            $NewItem.SubItems.Add( [string]$FriendlyName )
            $NewItem.SubItems.Add( $RoundedSize )
            $NewItem.SubItems.Add( $Date )
            $VMCListView.Items.Add( $NewItem )
        }
    }
}
function Get-VMC {
    param (
        $VMCFile
    )
    if ( -not $VMCFile ) {
        $VMCFile = Set-File "VMC File (*.bin)|*.bin"
    }
    if ( $VMCFile ) {
        $VMCFileSize = ( Get-Item $VMCFile ).Length
        Find-Error

        if ( $VMCFileSize -le 0x20000000 -and $VMCFileSize -ge 0x400000 -and ( $VMCFileSize % 0x400000 ) -eq 0 ) {

            $VMCListView.Items.Clear()

            $LabelVMC.Text = $VMCFile

            $VMCFileInfo = & $VMCTool $VMCFile --mc-info

            $TextBoxVMCInfo.Text = $null

            foreach ( $Line in $VMCFileInfo ) {
                if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                    $TextBoxVMCInfo.Text += "$Line`r`n"
                }
            }
            if ( $TextBoxVMCInfo -match $UnreadableMessage ) {
                $TextBoxVMCInfo.Text += "The VMC file is unreadable.`r`n"
            }
            else {
                $VMCFreespace = & $VMCTool $VMCFile --mc-free
                
                foreach ($Line in $VMCFreespace) {
                    if ( $Line -notmatch "PS2VMC-TOOL v|PS2 Memory Card free space|Calculating free space" ) {
                        $TextBoxVMCInfo.Text += "$Line`r`n"
                    }
                }
                Get-VMCList $VMCFile
            }
        }
        else {
            Write-Form "`r`nAn error has occured:`r`n`r`nThe Selected VMC File is either too big, too small, or not 4MB or 8MB (8388608 byte) aligned.`r`nThe VMC File Size is $( $VMCFileSize / 1024 / 1024 ) MB.`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
        }
    }
}
$MainForm = New-Object $FormObject
$MainForm.Text = "PS2 Virtual Memory Card GUI"
$MainForm.AutoSize = $true
$MainForm.FormBorderStyle = "FixedSingle"
$MainForm.Height = "690"
$MainForm.Font = New-Object System.Drawing.Font( "Segoe UI" , 12 )

$LabelChooseVMC = New-Object $LabelObject
$LabelChooseVMC.Text = "Please Choose a VMC file (.bin):"
$LabelChooseVMC.AutoSize = $true
$LabelChooseVMC.Location = New-Object System.Drawing.Point( 20 , 26 )
$MainForm.Controls.Add( $LabelChooseVMC )

$ButtonSelectVMC = New-Object $ButtonObject
$ButtonSelectVMC.Text = "Open File"
$ButtonSelectVMC.AutoSize = $true
$ButtonSelectVMC.Location = New-Object System.Drawing.Point( 260 , 20 )
$ButtonSelectVMC.Add_Click( {
    Get-VMC
} )
$MainForm.Controls.Add( $ButtonSelectVMC )

$ButtonCreateVMC = New-Object $ButtonObject
$ButtonCreateVMC.Text = "Create New"
$ButtonCreateVMC.AutoSize = $true
$ButtonCreateVMC.Location = New-Object System.Drawing.Point( 360 , 20 )
$ButtonCreateVMC.Add_Click( {

    $NewVMC = Set-VMCFile "NewVMC8MB.bin"
    if ( $NewVMC ) {
        Expand-Archive -Path $BlankVMCZip -DestinationPath $TempDir -Force

        Move-Item -Path "$TempDir\BlankVMC.bin" -Destination $NewVMC -Force
        
        if ( -not ( Find-Error ) ) {

            $FormatInfo = & $VMCTool $NewVMC --mc-format

            $FormFormatInfo = $null
            foreach ($Line in $FormatInfo) {
                $FormFormatInfo += "$Line`r`n"
            }
            Write-Form $FormFormatInfo "Format Complete"

            $LabelVMC.Text = $NewVMC
            Get-VMC $LabelVMC.Text
        }
    }
} )
$MainForm.Controls.Add( $ButtonCreateVMC )

$CheckBoxArt = New-Object $CheckBoxObject
$CheckBoxArt.AutoSize = $true
# $CheckBoxArt.Checked = $true
$CheckBoxArt.Checked = $false
$CheckBoxArt.Text = "Enable Box Art"
$CheckBoxArt.Location = New-Object System.Drawing.Point( 560 , 26 )
$CheckBoxArt.Add_Click( {
    if ( -not $CheckBoxArt.Checked ) {
        $ArtPictureBox.Image = $null
        $ArtPictureBox.Width = "0"
        $MainForm.AutoSize = $false
        $MainForm.AutoSize = $true
    }
} )
$MainForm.Controls.Add( $CheckBoxArt )

$LabelVMC = New-Object $LabelObject
$LabelVMC.Text = $null
$LabelVMC.AutoSize = $true
$LabelVMC.Location = New-Object System.Drawing.Point( 20 , 56 )
$MainForm.Controls.Add( $LabelVMC )

$TextBoxVMCInfo = New-Object $TextBoxObject
$TextBoxVMCInfo.Text = $WelcomeMessage
$TextBoxVMCInfo.ReadOnly = $true
$TextBoxVMCInfo.Multiline = $true
$TextBoxVMCInfo.TabStop = $false
$TextBoxVMCInfo.ScrollBars = "Vertical"
$TextBoxVMCInfo.ClientSize = "780 , 156"
$TextBoxVMCInfo.Location = New-Object System.Drawing.Point( 20 , 84 )
$MainForm.Controls.Add( $TextBoxVMCInfo )

$ButtonFormat = New-Object $ButtonObject
$ButtonFormat.Text = "ERASE and Format VMC"
$ButtonFormat.AutoSize = $true
$ButtonFormat.BackColor = "Pink"
$ButtonFormat.Location = New-Object System.Drawing.Point( 20 , 248 )
$ButtonFormat.Add_Click( {
    if ( $LabelVMC.Text ) {

        if ( $TextBoxVMCInfo -notmatch "$WelcomeMessage|$UnreadableMessage" ) {

            $Result = Write-Form "WARNING THIS WILL DELETE ALL SAVE DATA`r`n`r`nARE YOU SURE?" "WARNING THIS WILL DELETE ALL SAVE DATA"
            if ( $Result -match "Cancel") {
                return
            }
            elseif ( $Result -match "OK" ) {

                $FormatInfo = & $VMCTool $LabelVMC.Text --mc-format

                $FormFormatInfo = $null
                foreach ($Line in $FormatInfo) {
                    $FormFormatInfo += "$Line`r`n"
                }
                Write-Form $FormFormatInfo "Format Complete"

                Get-VMC $LabelVMC.Text
            }
        }
    }
} )
$MainForm.Controls.Add( $ButtonFormat )

$ButtonImport = New-Object $ButtonObject
$ButtonImport.Text = "Import Save File (.psu)"
$ButtonImport.AutoSize = $true
$ButtonImport.Location = New-Object System.Drawing.Point( 220 , 248 )
$ButtonImport.Add_Click( {
    if ( $LabelVMC.Text ) {

        $ImportPsu = Set-File "LaunchELF (.psu)|*.psu"
        if ( $ImportPsu -match ".psu" ) {
            
            $PsuFileSize = ( Get-Item $ImportPsu ).Length
            if ( $PsuFileSize -lt 0x600000 ) {

                $ImportInfo = & $VMCTool $LabelVMC.Text --psu-import $ImportPsu

                if ( $ImportInfo -match "Error: can't import file" ) {

                    $FormImportInfo = $null
                    foreach ($Line in $ImportInfo) {
                        $FormImportInfo += "$Line`r`n"
                    }
                    Write-Form "`r`nAn error has occured:`r`n`r`nThere may not be enough available space on VMC.`r`n`r`n$FormImportInfo`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                }
                else {
                    foreach ( $Line in $ImportInfo ) {
                        if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                            Write-Host $Line
                        }
                    }
                }
                Get-VMC $LabelVMC.Text
            }
            else {
                Write-Form "`r`nAn error has occured:`r`n`r`nThe Selected LaunchELF .psu file is too large.`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
            }
        }
    }
} )
$MainForm.Controls.Add( $ButtonImport )

$ButtonImportPSV = New-Object $ButtonObject
$ButtonImportPSV.Text = "Import Save File (.PSV)"
$ButtonImportPSV.AutoSize = $true
$ButtonImportPSV.Location = New-Object System.Drawing.Point( 408 , 248 )
$ButtonImportPSV.Add_Click( {
    if ( $LabelVMC.Text ) {

        $ImportPSV = Set-File "PS2 Save for PS3 (.PSV)|*.PSV"
        if ( $ImportPSV -match ".PSV" ) {

            $PSVFileSize = ( Get-Item $ImportPSV ).Length
            if ( $PSVFileSize -lt 0x600000 ) {

                $ImportInfo = & $VMCTool $LabelVMC.Text --psv-import $ImportPSV

                if ( $ImportInfo -match "Error: can't import file" ) {

                    $FormImportInfo = $null
                    foreach ($Line in $ImportInfo) {
                        $FormImportInfo += "$Line`r`n"
                    }
                    Write-Form "`r`nAn error has occured:`r`n`r`nThere may not be enough available space on VMC.`r`n`r`n$FormImportInfo`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                }
                else {
                    foreach ( $Line in $ImportInfo ) {
                        if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                            Write-Host $Line
                        }
                    }
                }
                Get-VMC $LabelVMC.Text
            }
            else {
                Write-Form "`r`nAn error has occured:`r`n`r`nThe Selected save file .PSV file is too large.`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
            }
        }
    }
} )
$MainForm.Controls.Add( $ButtonImportPSV )

$VMCListView = New-Object $ListViewObject
$VMCListView.Location = New-Object System.Drawing.Point( 20 , 285 )
$VMCListView.Size = New-Object System.Drawing.Point( 780 , 310 )
$VMCListView.View = "Details"
$VMCListView.FullRowSelect = $true
$VMCListView.MultiSelect = $false
$VMCListView.Sorting = "Ascending"
$VMCListView.Items.Clear()
$VMCListView.Columns.Add( "Name" ) | Out-Null
$VMCListView.Columns[0].Width = 260
$VMCListView.Columns.Add( "Friendly Name" ) | Out-Null
$VMCListView.Columns[1].Width = 328
$VMCListView.Columns.Add( "Size" ) | Out-Null
$VMCListView.Columns[2].TextAlign = "Right"
$VMCListView.Columns[2].Width = 70
$VMCListView.Columns.Add( "Date" ) | Out-Null
$VMCListView.Columns[3].TextAlign = "Right"
$VMCListView.Columns[3].Width = 100
$VMCListView.Add_Click( {
    if ( $CheckBoxArt.Checked ) {
        $RawNameMask = $VMCListView.SelectedItems.Text -replace '"............'
        $TrimName = $VMCListView.SelectedItems.Text -replace "$RawNameMask|`".."
        Find-Error
        $ErrorActionPreference = "SilentlyContinue"
        $BoxArt = Invoke-WebRequest -Uri "$( $BoxArtDatabase )$TrimName.jpg"
        $ErrorActionPreference = "Continue"
        if ( -not $Error ) {
            $ArtPictureBox.Size = New-Object System.Drawing.Point( 452 , 648 )
            $ArtPictureBox.Image = ( $BoxArt.Content )
        }
        else {
            $Error.Clear()
            $ArtPictureBox.Image = $null
            $ArtPictureBox.Width = "0"
            $MainForm.AutoSize = $false
            $MainForm.AutoSize = $true
        }
    }
    
} )
$MainForm.Controls.Add( $VMCListView )

$ButtonFormat = New-Object $ButtonObject
$ButtonFormat.Text = "DELETE Save"
$ButtonFormat.AutoSize = $true
$ButtonFormat.BackColor = "Pink"
$ButtonFormat.Location = New-Object System.Drawing.Point( 20 , 600 )
$ButtonFormat.Add_Click( {
    if ( $LabelVMC.Text ) {

        if ( $TextBoxVMCInfo -notmatch "$WelcomeMessage|$UnreadableMessage" ) {

            if ( -not $VMCListView.SelectedItems.Count ) {
                Write-Form "Please Select a Save to Delete." "Please Select a Save to Delete"
            }
            else {
                $Result = Write-Form "WARNING THIS WILL DELETE SAVE DATA`r`n`r`nARE YOU SURE?" "WARNING THIS WILL DELETE SAVE DATA"

                if ( $Result -match "Cancel") {
                    Get-VMC $LabelVMC.Text
                    return
                }
                elseif ( $Result -match "OK" ) {

                    $SelectedSave = $VMCListView.SelectedItems.Text

                    $SaveDirTable = & $VMCTool $LabelVMC.Text --list $SelectedSave

                    foreach ( $SaveDirLine in $SaveDirTable ) {

                        if ( $SaveDirLine -notmatch 'PS2VMC-TOOL v|----------|"."|".."' ) {

                            $SaveFileInfo = $SaveDirLine -split " / "
                            $FileName = $SaveFileInfo[0]

                            $DeleteInfo = & $VMCTool $LabelVMC.Text --remove $SelectedSave/$FileName

                            if ( $DeleteInfo -match "Error" ) {

                                $FormDeleteInfo = $null
                                foreach ($Line in $DeleteInfo) {
                                    $FormDeleteInfo += "$Line`r`n"
                                }
                                Write-Form "`r`nAn error has occured:`r`n`r`nThere was an error deleting $SelectedSave.`r`n`r`n$FormDeleteInfo`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                            }
                            else {
                                foreach ( $Line in $DeleteInfo ) {
                                    if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                                        Write-Host $Line
                                    }
                                }
                            }
                        }
                    }
                    $DeleteDirInfo = & $VMCTool $LabelVMC.Text --remove-directory $SelectedSave
                    if ( $DeleteDirInfo -match "Error" ) {

                        $FormDeleteDirInfo = $null
                        foreach ($Line in $DeleteDirInfo) {
                            $FormDeleteDirInfo += "$Line`r`n"
                        }
                        Write-Form "`r`nAn error has occured:`r`n`r`nThere was an error deleting $($VMCListBox.SelectedItem).`r`n`r`n$FormDeleteDirInfo`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                    }
                    else {
                        foreach ( $Line in $DeleteDirInfo ) {
                            if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                                Write-Host $Line
                            }
                        }
                    }
                    Get-VMC $LabelVMC.Text
                }
            }
        }
    }
} )
$MainForm.Controls.Add( $ButtonFormat )


$ButtonExport = New-Object $ButtonObject
$ButtonExport.Text = "Export Save File (.psu)"
$ButtonExport.AutoSize = $true
$ButtonExport.Location = New-Object System.Drawing.Point( 140 , 600 )
$ButtonExport.Add_Click( {
    if ( $LabelVMC.Text ) {

        if ( $TextBoxVMCInfo -notmatch "$WelcomeMessage|$UnreadableMessage" ) {

            if ( -not $VMCListView.SelectedItems.Count ) {
                Write-Form "Please Select a Save to Export." "Please Select a Save to Export"
            }
            else {
                $SelectedSave = $VMCListView.SelectedItems.Text
                $ExportTarget = Set-SaveFile ($SelectedSave -replace '"')

                if ( $ExportTarget ) {

                    $ExportInfo = & $VMCTool $LabelVMC.Text --psu-export $SelectedSave $ExportTarget
                    if ( $ExportInfo -match "Error" ) {

                        $FormExportInfo = $null
                        foreach ( $Line in $ExportInfo ) {
                            $FormExportInfo += "$Line`r`n"
                        }
                        Write-Form "`r`nAn error has occured:`r`n`r`nThere was an error exporting $SelectedSave.`r`n`r`n$FormExportInfo`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                    }
                    else {
                        $DefaultDir.Text = ( Get-Item $ExportTarget ).Directory
                        foreach ( $Line in $ExportInfo ) {
                            if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                                Write-Host $Line
                            }
                        }
                    }
                }
            }
        }
    }
} )
$MainForm.Controls.Add( $ButtonExport )

$ButtonExportAll = New-Object $ButtonObject
$ButtonExportAll.Text = "Export ALL Saves (.psu)"
$ButtonExportAll.AutoSize = $true
$ButtonExportAll.Location = New-Object System.Drawing.Point( 330 , 600 )
$ButtonExportAll.Add_Click( {
    if ( $LabelVMC.Text ) {

        if ( $TextBoxVMCInfo -notmatch "$WelcomeMessage|$UnreadableMessage" ) {

            if ( $VMCListView.Items.Count ) {

                $ExportFolder = Set-Folder
                if ( $ExportFolder ) {

                    foreach ( $Save in $VMCListView.Items ) {

                        $SelectedSave = $Save.Text
                        $ExportTarget = "$ExportFolder\$($SelectedSave -replace '"').psu"

                        $ExportInfo = & $VMCTool $LabelVMC.Text --psu-export $SelectedSave $ExportTarget
                        if ( $ExportInfo -match "Error" ) {

                            $FormExportInfo = $null
                            foreach ($Line in $ExportInfo) {
                                $FormExportInfo += "$Line`r`n"
                            }
                            Write-Form "`r`nAn error has occured:`r`n`r`nThere was an error exporting $SelectedSave.`r`n`r`n$FormExportInfo`r`n`r`n$( $Error -join "`r`n`r`n" )" "Error"
                        }
                        else {
                            foreach ( $Line in $ExportInfo ) {
                                if ( $Line -notmatch "PS2VMC-TOOL v" ) {
                                    Write-Host $Line
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} )
$MainForm.Controls.Add( $ButtonExportAll )

$ButtonCancel = New-Object $ButtonObject
$ButtonCancel.Text = "Exit"
$ButtonCancel.AutoSize = $true
$ButtonCancel.Location = New-Object System.Drawing.Point( 720 , 600 )
$MainForm.CancelButton = $ButtonCancel
$MainForm.Controls.Add( $ButtonCancel )

$ArtPictureBox = New-Object $PictureBoxObject
$ArtPictureBox.AutoSize = $true
$ArtPictureBox.Width = "0"
$ArtPictureBox.SizeMode = "Zoom"
$ArtPictureBox.Location = New-Object System.Drawing.Point( 820 , 0 )
$ArtPictureBox.Image = ( $BoxArt.Content )
$MainForm.Controls.Add( $ArtPictureBox )

Find-Error
if ( -not ( Test-Path $License ) ) {
    Write-Form "Error: License file not detected" "Error" | Out-Null
    exit
}
$LicenseResult = Write-Form ( Get-Content $License -Raw ) "Please Read the Software License"
# $LicenseResult = Write-Form ( Invoke-WebRequest -Uri $LicenseURI ).Content "Please Read the Software License"
Find-Error
if ( $Error ) {
    exit
}
if ( $LicenseResult -match "Cancel" ) {
    exit
}
if ( -not ( Test-Path $TempDir ) ) {
    New-Item $TempDir -ItemType "directory" | Out-Null
}
if ( ( -not ( Test-Path $VMCTool ) ) -or ( -not ( Test-Path $BlankVMCZip ) ) ) {
    # $SetupFilesZip = "$TempDir\SetupFiles.zip"
    # Invoke-WebRequest -Uri $SetupFilesURI -OutFile $SetupFilesZip
    # Expand-Archive $SetupFilesZip -DestinationPath $TempDir
    if ( Test-Path $SetupFilesZip ) {
        Expand-Archive $SetupFilesZip -DestinationPath $TempDir
    }
    else {
        Write-Form "Error: SetupFiles zip file not detected" "Error" | Out-Null
        exit
    }
}
Find-Error

$MainFormResult = $MainForm.ShowDialog()

Find-Error

if ( $MainFormResult -match "Cancel" ) {
    exit
}
