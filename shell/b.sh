#! /bin/sh

#使用方法：
#将文件夹里的b.sh、ADHOCExportOptionsPlist.plist和AppStoreExportOptionsPlist.plist放到你的工程根目录下(和你.xcodeproj文件同级)。

#ADHOCExportOptionsPlist.plist和AppStoreExportOptionsPlist.plist文件，使用Xcode(配置好项目证书)分别用Debug和Release模式打出ipa包里面相应模式的ExportOptionsPlist文件改名而成。

#########################/*配置开头*/##################
# 工程名
project_name="JiCaiLottery"
# scheme名
scheme_name="JiCaiLottery"

# 上传到 Fir
api_token="你的Fir token" # fir token
# 上传到蒲公英
uKey="你的蒲公英uKey"
apiKey="你的蒲公英apiKey"

#上传App Store
appleid="这里是你的appleid"
appleIDPWD="这里是你的appleid密码"

#Bugly
buglyAppKey="你的bugly app key"
buglyAppId="你的bugly app id"
bundleId="你的bundle id"

#########################/*配置结尾*/##################

#$0：当前Shell程序的文件名
#dirname $0，获取当前Shell程序的路径
#cd `dirname $0`，进入当前Shell程序的目录
#工程绝对路径
project_path=$(cd `dirname $0`; pwd)
# 桌面路径
desktop_path=~/Desktop

#获取日期和时间，用于设置存放xxxxxx.xcarchive和xxxxxx.ipa文件夹的后缀，便于之后查找相应的文件。
#包名后缀(日期+时间)
date="$(date "+%Y-%m-%d_%H-%M-%S")"
temp_date="_${date}"


#获取你所选择编译环境，read用来获取终端输入的值，这里用来获取你所选择1、2三种模式。
echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "

#读取用户输入的信息
read number
while([[ $number != 1 ]] && [[ $number != 2 ]])
do
echo "Error! Should enter 1 or 2"
echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "
read number
done
#根据前面选择的编译环境，选择ExportOptionsPlist文件。
if [ $number == 1 ];then
development_mode=Release
exportOptionsPlistPath=${project_path}/AppStoreExportOptionsPlist.plist

else
development_mode=Debug
exportOptionsPlistPath=${project_path}/ADHOCExportOptionsPlist.plist

fi

#通过Info.plist获取项目的version和build版本号，即设置version和build版本号
#app_name =$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" ${project_path}/${project_name}/Info.plist)

mainVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${project_path}/${project_name}/Info.plist)
mainBuild=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${project_path}/${project_name}/Info.plist)

new_mainVersion=$mainVersion
new_mainBuild=$mainBuild

echo "${project_name} version：$mainVersion build：$mainBuild"

echo "Do you want to set a new version for ${project_name} ? [ 1:NO 2:Build version + 1 3:YES ] "

#
read v_number
while([[ $v_number != 1 ]] && [[ $v_number != 2 ]] && [[ $v_number != 3 ]])
do
echo "Error! Should enter 1 、2、3"
echo "Do you want to set a new version for ${project_name} ? [ 1:YES 2:NO 3:Build version + 1 ] "
read v_number
done
#
if [ $v_number == 1 ];then
	echo "/+++++++ 未更改版本号 +++++++/"
elif [[ $v_number == 2 ]]; then
	#build + 1
	new_mainBuild=$((${mainBuild} + 1))
else
	echo "Please enter a new version:?"
	read version
	new_mainVersion=$version

	echo "Please enter a new build:?"
	read build
	new_mainBuild=$build

fi

# 设置新的Version 和 Build
plutil -replace CFBundleShortVersionString -string $new_mainVersion ${project_path}/${project_name}/Info.plist
plutil -replace CFBundleVersion -string $new_mainBuild ${project_path}/${project_name}/Info.plist

versionString="_${new_mainVersion}_${new_mainBuild}"

#Build文件夹路径,目前Build是放在桌面
build_path=${desktop_path}/IPA/Build/${project_name}${versionString}${temp_date}
#导出.ipa文件所在路径，IPA默认在桌面
exportIpaPath=${desktop_path}/IPA/${development_mode}/${project_name}${versionString}${temp_date}



#使用xcodebuild编译打包项目
echo '/+++++++ 正在清理工程 +++++++/'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit
echo '/+++++++ 清理完成 +++++++/'


echo '正在编译工程:'${development_mode}
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit
echo '/+++++++ 编译完成 +++++++/'


echo '/+++++++ 开始ipa打包 +++++++/'
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit
# 判断IPAs内是否有ipa包
if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo '/+++++++ ipa包已导出 +++++++/'
#打开文件
open $exportIpaPath

else

echo '/+++++++ ipa包导出失败 +++++++/'

fi

echo '/+++++++ 打包ipa完成 +++++++/'

echo '/+++++++ 开始发布ipa包 +++++++/'

if [ $number == 1 ];then




#上传App Store
echo '/+++++++ 上传App Store +++++++/'
#验证并上传到App Store

altoolPath="/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
"$altoolPath" --validate-app -f ${exportIpaPath}/$scheme_name.ipa -u "${appleid}" -p "${appleIDPWD}" -t ios --output-format xml
"$altoolPath" --upload-app -f ${exportIpaPath}/$scheme_name.ipa -u  "${appleid}" -p "${appleIDPWD}" -t ios --output-format xml

append_path="_AppStore"
# 修改存放ipa包文件夹路径，添加后缀，以便区分上传平台
mv $exportIpaPath $exportIpaPath$append_path
echo '/+++++++ 成功上传到App Store +++++++/'
else

#上传蒲公英
echo '/+++++++ 上传蒲公英 +++++++/'
PASSWORD=123456
#将git最后一次提交作为更新说明
MSG=`git log -1 --pretty=%B`
curl -F "file=@$exportIpaPath/$scheme_name.ipa" \
-F "uKey=${uKey}" \
-F "_api_key=${apiKey}" \
-F "updateDescription=${MSG}" \
-F "password=${PASSWORD}" \
https://qiniu-storage.pgyer.com/apiv1/app/upload

append_path="_pgyer"
mv $exportIpaPath $exportIpaPath$append_path
echo '/+++++++ 成功上传到蒲公英 +++++++/'

fi


#Bugly

#echo '/+++++++ 压缩dSYM文件 +++++++/'
#cd $build_path/$project_name.xcarchive/dSYMs
#zip -r -o ${project_name}.app.dSYM.zip "${project_name}.app.dSYM"
#echo '/+++++++ 压缩dSYM文件完成 +++++++/'
#
#
#echo '/+++++++ 上传dSYM文件 +++++++/'
#curl -k "https://api.bugly.qq.com/openapi/file/upload/symbol?app_key=$buglyAppKey&app_id=$buglyAppId" --form "api_version=1" --form "app_id=$buglyAppId" --form "app_key=$buglyAppKey" --form "symbolType=2"  --form "bundleId=${bundleId}" --form "productVersion=${new_mainVersion}(${new_mainBuild})" --form "channel=appstore" --form "fileName=$project_name.app.dSYM.zip" --form "file=@$build_path/$project_name.xcarchive/dSYMs/$project_name.app.dSYM.zip" --verbose
#echo '\n/+++++++ 上传dSYM文件结束 +++++++/'
#
#
#echo '/+++++++ 压缩symbol文件 +++++++/'
#cd $build_path/$project_name.xcarchive
#zip -r -o 'symbol.zip' "BCSymbolMaps"
#echo '\n/+++++++ 压缩symbol文件结束 +++++++/'
#
#
#echo '/+++++++ 上传Symbol文件 +++++++/'
#curl -k "https://api.bugly.qq.com/openapi/file/upload/symbol?app_key=$buglyAppKey&app_id=$buglyAppId" --form "api_version=1" --form "app_id=$buglyAppId" --form "app_key=$buglyAppKey" --form "symbolType=2"  --form "bundleId=${bundleId}" --form "productVersion=${new_mainVersion}(${new_mainBuild})" --form "fileName=symbol.zip" --form "file=@$build_path/$project_name.xcarchive/symbol.zip" --verbose
#echo '/+++++++ 上传Symbol文件结束 +++++++/'

# 获取info.plist文件中的Version和Build号
new_mainVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${project_path}/${project_name}/Info.plist)
new_mainBuild=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${project_path}/${project_name}/Info.plist)

echo "/+++++++ ${project_name} version:$new_mainVersion bulid:$new_mainBuild 编译打包上传完成！+++++++/"

# 输出打包总用时
echo "${__LINE_BREAK_LEFT} 打包并上传总耗时: ${SECONDS}s ${__LINE_BREAK_RIGHT}"


exit 0


