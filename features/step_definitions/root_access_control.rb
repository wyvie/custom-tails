Then /^I should be able to run administration commands as the live user$/ do
  stdout = $vm.execute("echo #{@sudo_password} | sudo -S whoami",
                       :user => LIVE_USER).stdout
  actual_user = stdout.sub(/^\[sudo\] password for #{LIVE_USER}: /, "").chomp
  assert_equal("root", actual_user, "Could not use sudo")
end

Then /^I should not be able to run administration commands as the live user with the "([^"]*)" password$/ do |password|
  stderr = $vm.execute("echo #{password} | sudo -S whoami",
                       :user => LIVE_USER).stderr
  sudo_failed = stderr.include?("The administration password is disabled") || stderr.include?("is not allowed to execute")
  assert(sudo_failed, "The administration password is not disabled:" + stderr)
end

When /^running a command as root with pkexec requires PolicyKit administrator privileges$/ do
  action = 'org.freedesktop.policykit.exec'
  action_details = $vm.execute("pkaction --verbose --action-id #{action}").stdout
  assert(action_details[/\s+implicit any:\s+auth_admin$/],
         "Expected 'auth_admin' for 'any':\n#{action_details}")
  assert(action_details[/\s+implicit inactive:\s+auth_admin$/],
         "Expected 'auth_admin' for 'inactive':\n#{action_details}")
  assert(action_details[/\s+implicit active:\s+auth_admin$/],
         "Expected 'auth_admin' for 'active':\n#{action_details}")
end

Then /^I should be able to run a command as root with pkexec$/ do
  step "I run \"pkexec touch /root/pkexec-test\" in GNOME Terminal"
  step 'I enter the sudo password in the pkexec prompt'
  try_for(10, :msg => 'The /root/pkexec-test file was not created.') {
    $vm.execute('ls /root/pkexec-test').success?
  }
end

Then /^I should not be able to run a command as root with pkexec and the standard passwords$/ do
  step "I run \"pkexec touch /root/pkexec-test\" in GNOME Terminal"
  ['', 'live', 'amnesia'].each do |password|
    deal_with_polkit_prompt(password, expect_success: false)
  end
  @screen.type(Sikuli::Key.ESC)
  @screen.wait('PolicyKitAuthCompleteFailure.png', 20)
end
