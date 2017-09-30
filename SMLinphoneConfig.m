//
//  SMLinphoneConfig.m
//  SiMiCloudShare
//
//  Created by MAC_OSSS on 17/4/17.
//  Copyright © 2017年 MAC_OSSS. All rights reserved.
//

#import "SMLinphoneConfig.h"
#import "LinphoneManager.h"


static SMLinphoneConfig *linphoneCfg = nil;
@implementation SMLinphoneConfig

+ (SMLinphoneConfig *)instance{

    @synchronized(self) {
        
        if (linphoneCfg == nil) {
            
            linphoneCfg = [[SMLinphoneConfig alloc] init];
        }
    }
    return linphoneCfg;
}
#pragma mark - 注册
- (void)registeByUserName:(NSString *)userName pwd:(NSString *)pwd domain:(NSString *)domain tramsport:(NSString *)transport{
    
    //设置超时
    linphone_core_set_inc_timeout(LC, 60);
    
    //创建配置表
    LinphoneProxyConfig *proxyCfg = linphone_core_create_proxy_config(LC);
   
    //初始化电话号码
    linphone_proxy_config_normalize_phone_number(proxyCfg,userName.UTF8String);
    
    //创建地址
    NSString *address = [NSString stringWithFormat:@"sip:%@@%@",userName,domain];//如:sip:123456@sip.com
    LinphoneAddress *identify = linphone_address_new(address.UTF8String);
   
    linphone_proxy_config_set_identity_address(proxyCfg, identify);
    
    linphone_proxy_config_set_route(
                                    proxyCfg,
                                    [NSString stringWithFormat:@"%s;transport=%s", domain.UTF8String, transport.lowercaseString.UTF8String]
                                    .UTF8String);
    linphone_proxy_config_set_server_addr(
                                          proxyCfg,
                                          [NSString stringWithFormat:@"%s;transport=%s", domain.UTF8String, transport.lowercaseString.UTF8String]
                                          .UTF8String);
    
    linphone_proxy_config_enable_register(proxyCfg, TRUE);
    
    
    //创建证书
    LinphoneAuthInfo *info = linphone_auth_info_new(userName.UTF8String, nil, pwd.UTF8String, nil, nil, linphone_address_get_domain(identify));
    
    //添加证书
    linphone_core_add_auth_info(LC, info);
    
    //销毁地址
    linphone_address_unref(identify);
    
    //注册
    linphone_proxy_config_enable_register(proxyCfg, 1);
    
    // 设置一个SIP路线  外呼必经之路
    linphone_proxy_config_set_route(proxyCfg,domain.UTF8String);
    
    //添加到配置表,添加到linphone_core
    linphone_core_add_proxy_config(LC, proxyCfg);
    
    //设置成默认配置表
    linphone_core_set_default_proxy_config(LC, proxyCfg);
    
    
    //设置音频编码格式
//    [self synchronizeCodecs:linphone_core_get_audio_codecs(LC)];

    [self synchronizeVideoCodecs:linphone_core_get_video_codecs(LC)];
    
}
#pragma mark - 设置音频编码格式
- (void)synchronizeCodecs:(const MSList *)codecs {
    
    PayloadType *pt;
    const MSList *elem;
    
    for (elem = codecs; elem != NULL; elem = elem->next) {
        
        pt = (PayloadType *)elem->data;
        
//        NSString *sreung = [NSString stringWithFormat:@"%s", pt->mime_type];
//        NSString *normalBt = [NSString stringWithFormat:@"%d",pt->clock_rate];
//       if ([sreung isEqualToString:@"G729"]) {
        
        linphone_core_enable_payload_type(LC,pt, YES);
        
//        }
//       else
//        {
//
//            linphone_core_enable_payload_type(LC, pt, 0);
//        }
        
    }
}
#pragma mark - 设置视频编码格式
- (void)synchronizeVideoCodecs:(const MSList *)codecs {
    
    PayloadType *pt;
    const MSList *elem;
    
    for (elem = codecs; elem != NULL; elem = elem->next) {
        
        pt = (PayloadType *)elem->data;
        NSString *sreung = [NSString stringWithFormat:@"%s", pt->mime_type];
        if ([sreung isEqualToString:@"H264"]) {
            
            linphone_core_enable_payload_type(LC, pt, 1);
            
        }else {
            
            linphone_core_enable_payload_type(LC, pt, 0);
        }
    }
}

- (NSMutableArray *)getAllEnableVideoCodec{

    NSMutableArray *codeArray = [NSMutableArray array];
   
    PayloadType *pt;
    const MSList *elem;
    
    for (elem =  linphone_core_get_video_codecs(LC); elem != NULL; elem = elem->next) {
        
        pt = (PayloadType *)elem->data;
        
        NSString *sreung = [NSString stringWithFormat:@"%s", pt->mime_type];
        if (linphone_core_payload_type_enabled(LC,pt)) {
            [codeArray addObject:sreung];
        }
    }
    return codeArray;
    
}
- (NSMutableArray *)getAllEnableAudioCodec{
    
    NSMutableArray *codeArray = [NSMutableArray array];
    NSMutableSet *mutableSet = [NSMutableSet set];
    
    PayloadType *pt;
    const MSList *elem;
    
    for (elem =  linphone_core_get_audio_codecs(LC); elem != NULL; elem = elem->next) {
        
        pt = (PayloadType *)elem->data;
        
        NSString *sreung = [NSString stringWithFormat:@"%s", pt->mime_type];
        if (linphone_core_payload_type_enabled(LC,pt)) {
            [codeArray addObject:sreung];
            [mutableSet addObject:sreung];
            
        }
    }
    
    return codeArray;
    
}
#pragma mark - 开启关闭视频编码
- (void)enableVideoCodecWithString:(NSString *)codec enable:(BOOL)enable{
    
    PayloadType *pt;
    const MSList *elem;
    
    for (elem = linphone_core_get_video_codecs(LC); elem != NULL; elem = elem->next) {
        
        pt = (PayloadType *)elem->data;
        NSString *sreung = [NSString stringWithFormat:@"%s", pt->mime_type];
        if ([sreung isEqualToString:codec]) {
            
           linphone_core_enable_payload_type(LC, pt, enable);
        }
    }
}
#pragma mark - 拨打电话
- (void)callPhoneWithPhoneNumber:(NSString *)phone withVideo:(BOOL)video{

    LinphoneProxyConfig *cfg = linphone_core_get_default_proxy_config(LC);
    if (!cfg) {
        return;
    }
    
    LinphoneAddress *addr = [LinphoneManager.instance normalizeSipOrPhoneAddress:phone];
    linphone_core_enable_video_display(LC,video);

    [LinphoneManager.instance call:addr];
    if (addr) {
        linphone_address_unref(addr);
    }
    
}
- (void)switchCamera{

    const char *currentCamId = (char *)linphone_core_get_video_device(LC);
    const char **cameras = linphone_core_get_video_devices(LC);
    const char *newCamId = NULL;
    int i;
    
    for (i = 0; cameras[i] != NULL; ++i) {
        if (strcmp(cameras[i], "StaticImage: Static picture") == 0)
            continue;
        if (strcmp(cameras[i], currentCamId) != 0) {
            newCamId = cameras[i];
            break;
        }
    }
    if (newCamId) {
       // LOGI(@"Switching from [%s] to [%s]", currentCamId, newCamId);
        linphone_core_set_video_device(LC, newCamId);
        LinphoneCall *call = linphone_core_get_current_call(LC);
        if (call != NULL) {
            linphone_call_update(call, NULL);
        }
    }
}
- (void)acceptCall{
    
    LinphoneCall *call = linphone_core_get_current_call(LC);
    if (call) {
        
        [[LinphoneManager instance] acceptCall:call evenWithVideo:YES];
        
    }
}

- (void)hold{
    
}

- (void)unhold{
    
}

- (void)remoteAccount{
    
}

- (void)haveCall{
    
}

- (void)muteMic{
    
}

- (void)enableSpeaker{
    
}

- (void)tabeSnapshot{
    
}

- (void)takePreviewSnapshot{
    
}

- (void)setVideoSize{
    
}

- (void)showVideo{
    
    
}

- (void)setRemoteVieoPreviewWindow:(UIView *)preview{
    
    linphone_core_set_native_preview_window_id(LC, (__bridge void *)(preview));
}

- (void)setNativeVideoPreviewWindow:(UIView *)preview{
    
    linphone_core_set_native_video_window_id(LC, (__bridge void *)(preview));
}
#pragma mark - 清除配置表
- (void)clearProxyConfig {
    
    linphone_core_clear_proxy_config([LinphoneManager getLc]);
    linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}
@end
