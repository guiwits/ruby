require 'fileutils'
require 'net/smtp'

# This compares the latest generated files against that is in my puppet repository and will email if the diff
# produces output otherwise it doesn't do any notifications. Some of the diff syntax for diff'ing files is
# listed below. I wanted minimal output.
# diff --width 250 --suppress-common-lines --side-by-side ~/chanfiles/chanfile_cit.dat /app/share/etc/ | head 
# diff_output = `diff --width 250 --suppress-common-lines --side-by-side #{puppet_dir}/chanfile_#{loc}.dat /home/steve/chanconfig/chanfile_#{loc}.dat`
# diff_output = `/usr/bin/diff --side-by-side --ignore-matching-lines='^#' --suppress-common-lines #{puppet_dir}/chanfile_#{loc}.dat /home/steve/chanconfig/chanfile_#{loc}.dat`
def compare_against_puppet
  envs = ['eew_build', 'eew_test', 'eew_prod']
  locs = ['cit', 'ucb', 'mp']
  email = false
  diff_aggregate = ""
  changes = " ################## Difference is between what is in the current puppet repository versus what was just generated #################\n"
  for loc in locs 
    diff_aggregate.concat("======================================================== chanfile_#{loc}.dat ========================================================\n")
    for env in envs
      puppet_dir = "/home/steve/puppet/environments/#{env}/modules/eewshare/files/app/share/etc"
      diff_output = `/usr/bin/diff --ignore-matching-lines='^#' --suppress-common-lines #{puppet_dir}/chanfile_#{loc}.dat /home/steve/chanconfig/chanfile_#{loc}.dat`
      if diff_output != ""
        email = true
        diff_aggregate.concat("#{diff_output}")
        puts "WARNING:: Changes detected between #{puppet_dir}/chanfile_#{loc}.dat and /home/steve/chanconfig/chanfile_#{loc}.dat."
        #puts "#{diff_output}"
      elsif
        puts "No changes detected between:\n #{puppet_dir}/chanfile_#{loc}.dat and /home/steve/chanconfig/chanfile_#{loc}.dat."
      end
    end
  end

  for line in "#{diff_aggregate}"
    line = " #{line}"
    changes.concat("#{line}")
  end

  if email == true
    puts "Emailing differences to email list"
    email_diff(changes, env, loc)
  end
end

# Generate the CIT channel files based off the query from
# the chanconfig.pl script.
def generate_daily_cit(chanconfig)
  system("/usr/bin/perl #{chanconfig} -cit > /home/steve/chanconfig/chanfile_cit.dat")
  return
end

# Generate the UCB channel files based off the query from
# the chanconfig.pl script.
def generate_daily_ucb(chanconfig)
  system("/usr/bin/perl #{chanconfig} -ucb > /home/steve/chanconfig/chanfile_ucb.dat")
  return
end

# Generate the Menlo Park channel files based off the query from
# the chanconfig.pl script.
def generate_daily_mp(chanconfig)
  system("/usr/bin/perl #{chanconfig} -mp > /home/steve/chanconfig/chanfile_mp.dat")
  return
end

# Method to send email.
def email_diff(diff_output, env, loc)
  time = Time.new
  subject_str = ""
  subject_str <<  "CIT, MP, UCB chanfiles compared against the #{env} puppet file -- #{time.strftime("%Y-%m-%d")} SRG"
  recipients = Array.new
  recipients << "Stephen R. Guiwits \<steve@email.com\>"
  recipients << "John Doe \<john@doe.come\>"
  
  opts = {}
  opts[:server]  ||= 'localhost'
  opts[:from]    ||= 'steve@email.com'
  opts[:subject] ||= "#{subject_str}"
  opts[:body]    ||= "#{diff_output}"

  msg = <<END_OF_MESSAGE
From: <#{opts[:from]}>
To: <#{opts[:to]}>
Subject: #{opts[:subject]}

#{opts[:body]} 
END_OF_MESSAGE

  Net::SMTP.start(opts[:server]) do |smtp|
   smtp.send_message msg, opts[:from], recipients 
  end
  return
end

# Main method
if __FILE__ == $PROGRAM_NAME
  ENV['LD_LIBRARY_PATH'] = '$LD_LIBRARY_PATH:/app/oracle/product/current64'
  chanconfig = '/home/steve/chanconfig/chanconfig.pl'

  # generate daily CIT channel file for compare
  puts "Generating CIT channel file"
  generate_daily_cit(chanconfig)

  # generate daily UCB channel file for compare
  puts "Generating UCB channel file"
  generate_daily_ucb(chanconfig)

  # generate daily MP channel file for compare
  puts "Generating Menlo Park channel file"
  generate_daily_mp(chanconfig)

  compare_against_puppet
  puts "#{$PROGRAM_NAME} exiting successfully."
end
