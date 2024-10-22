- [Manage SSH login options](#ssh)
  - [Disable root login](#s07)
  - [Enable root login](#s08)
  - [Disable password login](#s09)
  - [Enable password login](#s10)
  - [Disable Public key authentication login](#s11)
  - [Enable Public key authentication login](#s12)
  - [Disable OTP authentication](#s13)
  - [Enable OTP authentication](#s14)
  - [Generate new OTP authentication QR code](#s15)
  - [Show OTP authentication QR code](#s16)
  - [Disable last login banner](#s30)
  - [Enable last login banner](#s31)

# SSH

**description:** Manage SSH login options


## S07

**description:** Disable root login

**Command:** 
~~~
sed -i "s|^#\?PermitRootLogin.*|PermitRootLogin no|" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PermitRootLogin yes'  /etc/ssh/sshd_config
~~~

## S08

**description:** Enable root login

**Command:** 
~~~
sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PermitRootLogin no' /etc/ssh/sshd_config
~~~

## S09

**description:** Disable password login

**Command:** 
~~~
sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PasswordAuthentication yes' /etc/ssh/sshd_config
~~~

## S10

**description:** Enable password login

**Command:** 
~~~
sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config
~~~

## S11

**description:** Disable Public key authentication login

**Command:** 
~~~
sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PubkeyAuthentication yes' /etc/ssh/sshd_config
~~~

## S12

**description:** Enable Public key authentication login

**Command:** 
~~~
sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PubkeyAuthentication no' /etc/ssh/sshd_config
~~~

## S13

**description:** Disable OTP authentication

**Command:** 
~~~
clear, ! check_if_installed libpam-google-authenticator && ! check_if_installed qrencode || debconf-apt-progress -- apt-get -y purge libpam-google-authenticator qrencode, sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config || sed -i "0,/KbdInteractiveAuthentication/s//ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config, sed -i '/^auth required pam_google_authenticator.so nullok/ d' /etc/pam.d/sshd, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'ChallengeResponseAuthentication yes' /etc/ssh/sshd_config
~~~

## S14

**description:** Enable OTP authentication

**Command:** 
~~~
check_if_installed libpam-google-authenticator || debconf-apt-progress -- apt-get -y install libpam-google-authenticator, check_if_installed qrencode || debconf-apt-progress -- apt-get -y install qrencode, sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config, sed -i $'/KbdInteractiveAuthentication/{iChallengeResponseAuthentication yes\n:a;n;ba}' /etc/ssh/sshd_config || sed -n -i '/password updating/{p;:a;N;/@include common-password/!ba;s/.*\n/auth required pam_google_authenticator.so nullok\nauth required pam_permit.so\n/};p' /etc/pam.d/sshd, [ ! -f /root/.google_authenticator ] && qr_code generate, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed libpam-google-authenticator || ! check_if_installed qrencode || grep -q '^ChallengeResponseAuthentication no' /etc/ssh/sshd_config || ! grep -q 'ChallengeResponseAuthentication' /etc/ssh/sshd_config
~~~

## S15

**description:** Generate new OTP authentication QR code

**Command:** 
~~~
qr_code generate
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^ChallengeResponseAuthentication yes' /etc/ssh/sshd_config
~~~

## S16

**description:** Show OTP authentication QR code

**Command:** 
~~~
qr_code
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
grep -q '^ChallengeResponseAuthentication yes' /etc/ssh/sshd_config && [ -f /root/.google_authenticator ]
~~~

## S30

**description:** Disable last login banner

**Command:** 
~~~
sed -i "s/^#\?PrintLastLog.*/PrintLastLog no/" /etc/ssh/sshd_config, systemctl restart ssh.service 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PrintLastLog yes' /etc/ssh/sshd_config
~~~

## S31

**description:** Enable last login banner

**Command:** 
~~~
sed -i "s/^#\?PrintLastLog.*/PrintLastLog yes/" /etc/ssh/sshd_config, systemctl restart ssh.service 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PrintLastLog no' /etc/ssh/sshd_config
~~~

