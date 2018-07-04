#!/bin/sh

#使用方法： bash -l ./dis_package.sh


target_name="CarPooling.xcworkspace" # 有效值 ****.xcodeproj / ****.xcworkspace (cocoapods项目)
project_name="CarPooling" # 工程名
work_type="workspace" # 有效值 project / workspace (cocoapods项目)
# 上传到 Fir
api_token="092bc2990b890cc8da6b0cf3d6263e80" # fir token
# 上传到蒲公英
__PGYER_U_KEY="35a524e4da4d1c488fc7eb7dfdcb5da1"
__PGYER_API_KEY="8ac9de9132b33267f8d737b2ae060777"


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

fir p ${out_path}/$project_name.ipa -T $api_token -c 发布release版本

exit 0
