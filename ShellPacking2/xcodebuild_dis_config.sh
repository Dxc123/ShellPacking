#!/bin/sh

#要求：
#证书Xcode配置好（非自动管理）、  Bitcode设置为NO

#说明：xcodebuild_dis_config.plist 文件是Xcode（证书非自动管理）第一次打的AdHoc包 里ExportOptions.plist文件改名而成
#使用方法：
#1.把shellPacking2文件放在项目根目录下（与.xcodeproj同级）
#2.cd 工程目录/ShellPacking2/
#bash -l ./xcodebuild_dis_config.sh 或者 直接把.sh文件，拖到命令行里面也行

#########################/配置区域开头/#####################

# 有效值 ****.xcodeproj / ****.xcworkspace (cocoapods项目)
target_name="JiCaiLottery.xcworkspace"
# 工程名
project_name="JiCaiLottery"

# 有效值 project / workspace (cocoapods项目)
work_type="workspace"
# 上传到 Fir
api_token="092bc2990b890cc8da6b0cf3d6263e80" # fir token
# 上传到蒲公英
uKey="35a524e4da4d1c488fc7eb7dfdcb5da1"
apiKey="8ac9de9132b33267f8d737b2ae060777"

#########################/配置区域结尾/#####################

#$0：当前Shell程序的文件名
#dirname $0，获取当前Shell程序的路径
#cd `dirname $0`，进入当前Shell程序的目录
#获取当前shell脚本所在文件夹路径，即工程的绝对路径
sctipt_path=$(cd `dirname $0`; pwd)
#输出 sctipt_path
echo sctipt_path=${sctipt_path}
#工程路径
work_path=${sctipt_path}/..
#删除 build
rm -rf ${work_path}/build

#cd ../
#pod install --no-repo-update
#cd ${sctipt_path}

# 桌面路径
#desktop_path=~/Desktop


#生成xcode_build_ipa_dev文件夹路径（存放打的IPA包）

#包名后缀(日期+时间)
date="$(date "+%Y-%m-%d-%H-%M-%S")"
#out_sub_path=`date "+%Y-%m-%d-%H-%M-%S"`#创建子文件夹（以创建时间为名）
out_sub_path="_${date}"
#创建名为xcode_build_ipa_dis文件夹
out_base_path="xcode_build_ipa_dis"

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
versionString="_V${new_mainVersion}"

##导出.ipa文件所在路径，默认在工程里的xcode_build_ipa_dis文件下
#out_path=${work_path}/${out_base_path}/${out_sub_path}
out_path=${work_path}/${out_base_path}/${app_name}${versionString}${out_sub_path}

#创建一个指定的目录
mkdir -p ${out_path}


if [[ -s "$HOME/.rvm/ShellPacking2/rvm" ]] ; then
    source $HOME/.rvm/ShellPacking2/rvm
    rvm use system
fi

#使用xcodebuild编译打包项目
echo '/+++++++ 正在清理工程 +++++++/'
xcodebuild -$work_type ${work_path}/$target_name -scheme $project_name -configuration Release -sdk iphoneos clean
echo '/+++++++ 清理完成 +++++++/'

echo '/+++++++ 正在编译工程 +++++++/'
xcodebuild archive -$work_type ${work_path}/$target_name -scheme $project_name -configuration Release -archivePath ${out_path}/$project_name.xcarchive
echo '/+++++++ 编译完成 +++++++/'


echo '/+++++++ 开始ipa打包 +++++++/'
xcodebuild -exportArchive -archivePath ${out_path}/$project_name.xcarchive -exportPath ${out_path} -exportOptionsPlist ${sctipt_path}/xcodebuild_dis_config.plist

#输出ipa包路径
echo ${out_path}/$project_name.ipa

if [[ -s "$HOME/.rvm/ShellPacking2/rvm" ]] ; then
    source ~/.rvm/ShellPacking2/rvm
    rvm use default
fi






#上传Fir
#fir p ${out_path}/$project_name.ipa -T $api_token -c 发布AdHoc版本

#echo "\n🎉🎉🎉打包上传Fir成功！"
#if [ $? -eq 0 ]
#then
#echo "\n🎉🎉🎉打包上传Fir成功！🎉🎉🎉"
#else
#echo "😪😪😪打包上传Fir失败!😪😪😪"
#fi

#上传蒲公英
#curl -F "file=@${out_path}/$project_name.ipa" \
-F "uKey=${uKey}" \
-F "_api_key=${apiKey}" \
https://www.pgyer.com/apiv1/app/upload

#if [ $? -eq 0 ]
#then
#echo "\n🎉🎉🎉打包上传蒲公英成功!🎉🎉🎉"
#else
#echo "😪😪😪打包上传蒲公英失败!😪😪😪"
#fi

# 判断文件内是否有ipa包
if [ -e ${out_path}/$project_name.ipa ]; then
echo '/+++++++ 🎉🎉🎉ipa包已导出🎉🎉🎉 +++++++/'
#打开文件
open ${out_path}
else
echo '/+++++++ 😪😪😪ipa包导出失败😪😪😪 +++++++/'
fi


# 输出打包总用时
echo "${__LINE_BREAK_LEFT} 打包并上传总耗时: ${SECONDS}s ${__LINE_BREAK_RIGHT}"

# 发送邮件

exit 0
