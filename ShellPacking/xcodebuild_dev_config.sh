#!/bin/sh

#要求：
#证书Xcode配置好、  Bitcode设置为NO
#说明： xcodebuild_dev_config.plist 文件是Xcode第一次打的development包 里ExportOptions.plist文件改名而成；

#使用方法：
#1.把shellPacking文件放在项目根目录下（与.xcodeproj同级）
#2.cd 工程目录/ShellPacking/
#bash -l ./xcodebuild_dis_config.sh 或者 直接把.sh文件，拖到命令行里面也行



#*************** 填写配置信息开头 ***********************
target_name="你的工程名.xcworkspace" # 有效值 ****.xcodeproj / ****.xcworkspace (cocoapods项目)
project_name="你的工程名" # 工程名
work_type="workspace" # 有效值 project / workspace (cocoapods项目)
# 上传到 Fir
api_token="你的fir token" # fir token
# 上传到蒲公英
uKey="你的蒲公英uKey"
apiKey="你的蒲公英apiKey"

#*************** 填写配置信息结尾 ***********************
#$0：当前Shell程序的文件名
#dirname $0，获取当前Shell程序的路径
#cd `dirname $0`，进入当前Shell程序的目录
#获取当前shell脚本所在文件夹路径，即工程的绝对路径
sctipt_path=$(cd `dirname $0`; pwd)
echo sctipt_path=${sctipt_path}
#工程路径
work_path=${sctipt_path}/..
#删除 旧build
rm -rf ${work_path}/build

#cd ../
#pod install --no-repo-update
#cd ${sctipt_path}

date="$(date "+%Y-%m-%d-%H-%M-%S")"#包名后缀(日期+时间)
#out_sub_path=`date "+%Y-%m-%d-%H-%M-%S"`#创建子文件夹（以创建时间为名）
out_sub_path="_${date}"
out_base_path="xcode_build_ipa_dev"#创建名为xcode_build_ipa_dev文件夹

#app名称
app_name=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" ${work_path}/${project_name}/Info.plist)
#version版本号
mainVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${work_path}/${project_name}/Info.plist)
#build号
mainBuild=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${work_path}/${project_name}/Info.plist)
new_mainVersion=$mainVersion
new_mainBuild=$mainBuild
new_mainVersion=$mainVersion
new_mainBuild=$mainBuild
#versionString="_${new_mainVersion}_${new_mainBuild}"
versionString="_${new_mainVersion}"

##导出.ipa文件所在路径，默认在工程里的xcode_build_ipa_dev文件下
#out_path=${work_path}/${out_base_path}/${out_sub_path}
out_path=${work_path}/${out_base_path}/${app_name}${versionString}${out_sub_path}
#创建一个指定的目录
mkdir -p ${out_path}


if [[ -s "$HOME/.rvm/ShellPacking/rvm" ]] ; then
source $HOME/.rvm/ShellPacking/rvm
rvm use system
fi

#使用xcodebuild编译打包项目
echo '/+++++++ 正在清理工程 +++++++/'
xcodebuild -$work_type ${work_path}/$target_name -scheme $project_name -configuration Debug -sdk iphoneos clean
echo '/+++++++ 清理完成 +++++++/'

echo '/+++++++ 正在编译工程 +++++++/'
xcodebuild archive -$work_type ${work_path}/$target_name -scheme $project_name -configuration Debug -archivePath ${out_path}/$project_name.xcarchive
echo '/+++++++ 编译完成 +++++++/'


echo '/+++++++ 开始ipa打包 +++++++/'
xcodebuild -exportArchive -archivePath ${out_path}/$project_name.xcarchive -exportPath ${out_path} -exportOptionsPlist ${sctipt_path}/xcodebuild_dev_config.plist
#输出ipa路径
echo ${out_path}/$project_name.ipa

if [[ -s "$HOME/.rvm/ShellPacking/rvm" ]] ; then
source ~/.rvm/ShellPacking/rvm
rvm use default
fi

#上传Fir
fir p ${out_path}/$project_name.ipa -T $api_token -c 发布debug版本
if [ $? -eq 0 ]
then
echo "\n🎉🎉🎉打包上传Fir成功🎉🎉🎉"
else
echo "😪😪😪打包上传Fir失败😪😪😪"
fi



#上传蒲公英
curl -F "file=@${out_path}/$project_name.ipa" \
-F "uKey=${uKey}" \
-F "_api_key=${apiKey}" \
https://www.pgyer.com/apiv1/app/upload

if [ $? -eq 0 ]
then
echo "\n🎉🎉🎉打包上传蒲公英成功🎉🎉🎉"
else
echo "😪😪😪打包上传蒲公英失败😪😪😪"
fi

# 判断文件内是否有ipa包
if [ -e ${out_path}/$project_name.ipa ]; then
echo '/+++++++🎉🎉🎉 ipa包已导出🎉🎉🎉 +++++++/'
#打开文件
open ${out_path}
else
echo '/+++++++ 😪😪😪ipa包导出失败😪😪😪 +++++++/'
fi


# 输出打包总用时
echo "${__LINE_BREAK_LEFT} 打包并上传总耗时: ${SECONDS}s ${__LINE_BREAK_RIGHT}"

# 发送邮件给测试人员(有待研究🙄)



exit 0
