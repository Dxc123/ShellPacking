#!/bin/sh

#使用方法： bash -l ./xcodebuild_dis_config.sh


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


sctipt_path=$(cd `dirname $0`; pwd)
echo sctipt_path=${sctipt_path}
work_path=${sctipt_path}/..
rm -rf ${work_path}/build

#cd ../
#pod install --no-repo-update
#cd ${sctipt_path}


out_sub_path=`date "+%Y-%m-%d-%H-%M-%S"`
out_base_path="xcode_build_ipa_dis"
out_path=${work_path}/${out_base_path}/${out_sub_path}
mkdir -p ${out_path}


if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
    source $HOME/.rvm/scripts/rvm
    rvm use system
fi

xcodebuild -$work_type ${work_path}/$target_name -scheme $project_name -configuration Release -sdk iphoneos clean
xcodebuild archive -$work_type ${work_path}/$target_name -scheme $project_name -configuration Release -archivePath ${out_path}/$project_name.xcarchive

xcodebuild -exportArchive -archivePath ${out_path}/$project_name.xcarchive -exportPath ${out_path} -exportOptionsPlist ${sctipt_path}/xcodebuild_dis_config.plist

echo ${out_path}/$project_name.ipa

if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
    source ~/.rvm/scripts/rvm
    rvm use default
fi
#上传Fir
fir p ${out_path}/$project_name.ipa -T $api_token -c 发布release版本

if [ $? -eq 0 ]
then
echo "\n🎉🎉🎉打包上传Fir成功"
else
echo "打包上传Fir失败"
fi

#上传蒲公英
curl -F "file=@${out_path}/$project_name.ipa" \
-F "uKey=${uKey}" \
-F "_api_key=${apiKey}" \
https://www.pgyer.com/apiv1/app/upload

if [ $? -eq 0 ]
then
echo "\n🎉🎉🎉打包上传蒲公英成功"
else
echo "打包上传蒲公英失败"
fi

# 输出打包总用时
echo "${__LINE_BREAK_LEFT} 打包并上传总耗时: ${SECONDS}s ${__LINE_BREAK_RIGHT}"

# 发送邮件给测试人员(有待研究🙄)
exit 0
