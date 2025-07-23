#!/usr/bin/env fish

# Ref: https://github.com/tadfisher/pass-otp/pull/191/files#diff-776e240547b70c2944d72b18888df12d7427ef01e7f17d8bc63f97293c5b2146

# Source the original pass completion from nixpkgs
source @passCompletion@

# Add OTP completions
complete -c pass -f -n '__fish_pass_needs_command' -a otp -d 'Command: generate TOTP code'
complete -c pass -f -n '__fish_pass_uses_command otp' -s c -l clip -d 'Copy OTP to clipboard'
complete -c pass -f -n '__fish_pass_uses_command otp' -a "(__fish_pass_print_entries)"
