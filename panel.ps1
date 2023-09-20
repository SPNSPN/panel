add-type -AssemblyName System.Windows.Forms
add-type -AssemblyName System.Drawing

function message_sender {
	param($writer, $text)
	return {
		# ���b�Z�[�W���M
		$writer.WriteLine($script:text)
		$writer.Flush()
	}.GetNewClosure()
}

# ini�t�@�C����ǂݍ���
$path = "./panel.ini"
$settings = @{}
$pblist = new-object System.Collections.ArrayList
$lplist = new-object System.Collections.ArrayList
$sectionname = ""
cat $path | % {
	if ($_ -match "\[.*\]")
	{
		$sectionname = $_.substring(1, $_.length - 2)
		if ("PB" -eq $sectionname.substring(0, 2))
		{
			$pblist.Add($sectionname)
		}
		elseif ("LP" -eq $sectionname.substring(0, 2))
		{
			$lplist.Add($sectionname)
		}
	}
	elseif ($_ -match ".*=.*")
	{
		$key, $val = $_.split("=")
		$settings["${sectionname}::$key"] = $val
	}
}

# �\�P�b�g�쐬
$addr = [IPAddress]::Parse($settings["COMMON::IpAddress"])
$port = [Int32]::Parse($settings["COMMON::Port"])
$client = new-object System.Net.Sockets.TcpClient($addr, $port)
$stream = $client.GetStream()
$writer = new-object System.IO.StreamWriter $stream

# �t�H�[������
$form = new-object System.Windows.Forms.Form
$form.Text = "Panel App"
$form.Size = New-Object System.Drawing.Size($settings["COMMON::Width"], $settings["COMMON::Height"])
$form.MaximizeBox = $false
$form.FormBorderStyle = "FixedDialog"
$form.Font = new-object System.Drawing.Font("Meiryo UI", 8.5)

$pblist | % {
	# �{�^������
	$button = new-object System.Windows.Forms.Button
	$button.Text = $settings["${_}::Text"]
	$button.Location = new-object System.Drawing.Point($settings["${_}::X"], $settings["${_}::Y"])
	$button.Width = $settings["${_}::Width"]
	$button.Height = $settings["${_}::Height"]
	$button.Add_Click((message_sender $writer $_))

	$form.Controls.Add($button)
}

$lplist | % {
	# �����v����
	$button = new-object System.Windows.Forms.Button
	$button.Text = $settings["${_}::Text"]
	$button.Location = new-object System.Drawing.Point($settings["${_}::X"], $settings["${_}::Y"])
	$button.Width = $settings["${_}::Width"]
	$button.Height = $settings["${_}::Height"]

	$form.Controls.Add($button)
}

# �I�����̏���
$form.Add_Closing({
			param($sender, $e)
			$writer.Dispose()
			$stream.Dispose()
			$client.Dispose()
		})

$form.ShowDialog()
