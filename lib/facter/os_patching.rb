Facter.add('os_patching', :type => :aggregate) do
  #confine :kernel => "Linux"

  require 'time'
  now = Time.now.iso8601

  updatefile = "/etc/os_patching/package_updates"
  if File.file?(updatefile)
    updates = File.open(updatefile, "r").read
  end

  chunk(:updates) do
    data = {}
    updatelist = {}
    updatelist = Array.new
    if (updates)
      updates.each_line do |line|
        line.chomp
        next if line.empty?
        next if line.include? "^#"
        updatelist.push line
      end
    end
    data['package_updates'] = updatelist
    data['package_update_count'] = updatelist.count
    data
  end

  secupdatefile = "/etc/os_patching/security_package_updates"
  if File.file?(secupdatefile)
    secupdates = File.open(secupdatefile, "r").read
  end

  chunk(:secupdates) do
    data = {}
    secupdatelist = {}
    secupdatelist = Array.new
    if (secupdates)
      secupdates.each_line do |line|
        line.chomp
        next if line.empty?
        next if line.include? "^#"
        secupdatelist.push line
      end
    end
    data['security_package_updates'] = secupdatelist
    data['security_package_update_count'] = secupdatelist.count
    data
  end

  blackoutfile = "/etc/os_patching/blackout_windows"
  if File.file?(blackoutfile)
    blackouts = File.open(blackoutfile, "r").read
  end
  chunk(:blackouts) do
    data = {}
    arraydata = {}
    if (blackouts)
      blackouts.each_line do |line|
        matchdata = line.match(/^([\w ]*),([\d:T\-\\+]*),([\d:T\-\\+]*)$/)
        if (matchdata)
          if (!arraydata[matchdata[1]])
            arraydata[matchdata[1]] = {}
            if (matchdata[2] > matchdata[3])
              arraydata[matchdata[1]]['start'] = 'Start date after end date'
              arraydata[matchdata[1]]['end'] = 'Start date after end date'
            else
              arraydata[matchdata[1]]['start'] = matchdata[2]
              arraydata[matchdata[1]]['end'] = matchdata[3]
            end
          end

          if (matchdata[2] .. matchdata[3]).cover?(now)
            if (!data['blocked'])
              data['blocked'] = Array.new
            end
            data['blocked'].push matchdata[1]
          end
        end
      end
    end
    data['blackouts'] = arraydata
    data
  end


  # Are there any pinned packages in yum?
  pinnedpackagefile = '/etc/yum/pluginconf.d/versionlock.list'
  if File.file?(pinnedpackagefile)
    pinnedfile = File.open(pinnedpackagefile, "r").read
  end
  chunk(:pinned) do
    data = {}
    pinnedpkgs = {}
    pinnedpkgs = Array.new
    if (pinnedfile)
      pinnedfile.each_line do |line|
        matchdata = line.match(/^[0-9]:(.*)/)
        if (matchdata)
          pinnedpkgs.push matchdata[1]
        end
      end
    end
    data['pinned_packages'] = pinnedpkgs
    data
  end
end
