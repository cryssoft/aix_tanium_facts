#
#  FACT(S):     aix_tanium
#
#  PURPOSE:     This custom fact returns a simple fact hash that can be used
#		to fill in the AIX Tanium web page on the dashboard.
#
#  RETURNS:     (hash)
#
#  AUTHOR:      Chris Petersen, Crystallized Software
#
#  DATE:        February 10, 2021
#
#  NOTES:       Myriad names and acronyms are trademarked or copyrighted by IBM
#               including but not limited to IBM, PowerHA, AIX, RSCT (Reliable,
#               Scalable Cluster Technology), and CAA (Cluster-Aware AIX).  All
#               rights to such names and acronyms belong with their owner.
#
#-------------------------------------------------------------------------------
#
#  LAST MOD:    December 17, 2021
#
#  MODIFICATION HISTORY:
#
#  2021/12/17 - cp - Adding data collection for more configuration stuff, since
#		there's a new interface for it, and all of the AIX boxes we have
#		running this [stuff] should be on the 7.x release with it.
#
#-------------------------------------------------------------------------------
#
Facter.add(:aix_tanium) do
    #  This only applies to the AIX operating system
    confine :osfamily => 'AIX'

    #  Define an somewhat empty hash for our output
    l_aixTANIUM                     = {}
    l_aixTANIUM['running']          = false

    #  Do the work
    setcode do
        #  Run the command to look through the process list for the Tidal daemon
        l_lines = Facter::Util::Resolution.exec('/bin/ps -ef 2>/dev/null')

        #  Loop over the lines that were returned
        l_lines && l_lines.split("\n").each do |l_oneLine|
            #  Skip comments and blanks
            l_oneLine = l_oneLine.strip()
            #  Look for a telltale and rip apart that line
            if (l_oneLine =~ /\/opt\/Tanium\/TaniumClient\/TaniumClient -d/)
                l_aixTANIUM['running'] = true
            end
        end

        #  If we set the flag in the previous loop, loop over the config list
        if (l_aixTANIUM['running'])
            l_lines = Facter::Util::Resolution.exec('/opt/Tanium/TaniumClient/TaniumClient config list 2>/dev/null')
            l_lines && l_lines.split("\n").each do |l_oneLine|
                #  
                l_oneLine = l_oneLine.strip()
                l_pieces  = l_oneLine.split()
                #  Only deal with things that start with a dash
                if ((l_pieces[0] == '-') and (l_pieces[1] != 'Status:'))
                    l_name  = l_pieces[1].slice(0..-2)
                    l_value = l_pieces.slice(2..-1).join(' ')
                    l_aixTANIUM[l_name] = l_value
                end
            end
        end

        #  Implicitly return the contents of the variable
        l_aixTANIUM
    end
end
