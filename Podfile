platform :ios, '7.0'
pod 'Dropbox-Sync-API-SDK', '~> 2.1.0'


# Resolving CocoaPods Build Error Due to Targets Building for Only Active Architecture
# for 32bit arch only target

post_install do |installer_representation|
    installer_representation.project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end