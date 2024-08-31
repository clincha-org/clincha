1. Download and write the iso using Rufus
2. Put the USB, keyboard and monitor into the server you're configuring
3. Boot the device and press F2 until you get to the boot screen
4. Press F7 and then the right arrow key until it is over the "Boot" tab near the top
5. Use the down arrow key to select the "SanDisk" option in the "Boot Override" section
6. Press Enter
7. Use the down arrow to select "Advanced Options" and press Enter
8. Use the down arrow to select "Install Proxmox VE (Terminal UI, Debug Mode) and press "e"
9. Press the down arrow until the cursor is on the same line as the line starting with "linux"
10. Press the "end" key and press the spacebar. Then type "nomodeset".
11. Press ctrl + x
12. When the installer stops with a prompt saying "Debugging mode (type exit or press CTRL-D to continue startup)", press ctrl + d. This will happen a couple of times.
13. Press "I agree" (Enter)
14. Press "Next" (Enter)
15. Press "Next" (Enter)
16. Set a password and email address and then press "Next" (Enter)
17. Set the hostname with the domain, set the IP address and then press "Next" (Enter)
18. Press "Install" (right arrow + Enter)
19. At this point the install may fail. Turn the system off and retry. It should work the second time.
20. Press ctrl + d when prompted and let the machine boot a couple of times