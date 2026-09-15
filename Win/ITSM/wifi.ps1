echo Realtek 8852CE Wi-Fi 6E PCI-E NIC
pause
echo Disabling 6G 
powershell "Set-NetAdapterAdvancedProperty -Name '*' -RegistryKeyword 'WifiProtocol_6G' -RegistryValue '0'"
echo Enabling 6G
powershell "Set-NetAdapterAdvancedProperty -Name '*' -RegistryKeyword 'WifiProtocol_6G' -RegistryValue '34'"
echo "Check if wi-fi networks are reappeared. If they did - close the window. If not, press <Enter> to try something else"
pause
echo Disabling 2G (sometimes those cards do not work when 2G is enabled)
powershell "Set-NetAdapterAdvancedProperty -Name '*' -RegistryKeyword 'WifiProtocol_2g' -RegistryValue '0'"
echo "Check if wi-fi networks are reappeared. If they did - close the window. If not, press <Enter> to try something else"
pause
echo Enabling 2G
powershell "Set-NetAdapterAdvancedProperty -Name '*' -RegistryKeyword 'WifiProtocol_2g' -RegistryValue '45'"
echo "Check if wi-fi networks are reappeared. If they did - close the window. If not, press <Enter> to try something else"
pause


echo Boom. Done!
