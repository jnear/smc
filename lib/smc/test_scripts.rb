require File.expand_path(File.dirname(__FILE__) + '/main')

SMC.analyze do
  exposures_file '/home/ubuntu/derailer/lib/derailer/viz/exposures.rb'
  mapping User: ModelUser, 
          Room: OwnedObject(user: owners)
end

