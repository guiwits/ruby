#!/usr/bin/env ruby

require 'socket'
require 'timeout'

def CheckEWData
  current_path     = ENV['PATH']
  output           = ""
  sniffwave_output = ""
  start_time       = ""
  end_time         = ""
  secs_of_data     = ""
  bytes_of_data    = ""
  num_of_packets   = ""

  # Earthworm environment variables
  ENV['EW_HOME']         = "/app/eewdata/ew"
  ENV['EW_VERSION']      = "current"
  ENV['SYS_NAME']        = Socket.gethostname
  ENV['EW_INSTALLATION'] = "INST_CIT"
  ENV['EW_PARAMS']       = "/app/eewdata/run/params"
  ENV['EW_LOG']          = "/app/eewdata/run/logs"
  ENV['PATH']            = "#{current_path}:/app/eewdata/ew/earthworm_7.7/bin"  


  # First check that EW is even running
  ew_status = `/app/eewdata/run/bin/run_earthworm.sh status`
  status = ""
  for line in ew_status
    if ( line =~ /DOWN/ )
      status = "Earthworm is not running. CRITICAL"
      puts "#{status}"
      exit(2)
    end
  end

  # EW information
  seismo_ring_name = "WAVE_RING"
  gps_ring_name    = "GPS_WAVE_RING"

  sniffwave = "/app/eewdata/ew/earthworm_7.7/bin/sniffwave \
              #{seismo_ring_name} wild wild wild wild 5"

  # raises an exception if timeout is met
  begin
   Timeout::timeout(10) { 
    output = `#{sniffwave}`
   }
   rescue Timeout::Error
     puts "Couldn't run sniffwave before timeout was encountered."
  end

  unless output.to_s.strip.empty?
    sniffwave_output = output.split("\n")
    secs_of_data     = Float(sniffwave_output[-3].split(' ')[-1])
    bytes_of_data    = Integer(sniffwave_output[-2].split(' ')[-1])
    num_of_packets   = Integer(sniffwave_output[-1].split(' ')[-1])
  else
    status = "Unable to run sniffwave. Shared memory could be corrupt. CRITICAL"
    puts "#{status}"
    exit(2)
  end

  if num_of_packets > 0 and bytes_of_data > 0
    status = "Logged #{bytes_of_data} bytes of data; #{num_of_packets}" \
             "packets in #{secs_of_data} of data capture. OK"
    puts "#{status}"
    exit(0)
  else
    status = "Logged #{bytes_of_data} bytes of data; #{num_of_packets}" \
             "packets in #{secs_of_data} of data capture. CRITICAL" 
    puts "#{status}"
    exit(2)
  end
end

if __FILE__ == $PROGRAM_NAME
  CheckEWData()
end


