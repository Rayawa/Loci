import { common } from '@kit.AbilityKit';
import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

@ObservedV2
export class HuaweiAccount {
  static readonly shared: HuaweiAccount = new HuaweiAccount();
  @Trace configured: boolean = false;
  @Trace authorized: boolean = false;
  @Trace busy: boolean = false;
  @Trace message: string = '';

  initialize(context: common.UIAbilityContext): void {
    this.configured = context.currentHapModuleInfo.metadata?.some((item) => item.name === 'client_id' && !!item.value?.trim()) ?? false;
  }

  async login(context: common.UIAbilityContext): Promise<void> {
    if (this.busy) { return; }
    this.initialize(context);
    if (!this.configured) { this.message = '华为账号服务尚未开通，你可以继续在本机记录。'; return; }
    this.busy = true; this.message = '';
    try {
      const request = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
      const state = util.generateRandomUUID();
      request.state = state; request.forceLogin = true;
      const response = await new authentication.AuthenticationController(context).executeRequest(request) as authentication.LoginWithHuaweiIDResponse;
      if (response.state !== state || !response.data?.openID) { throw new Error('Invalid account response'); }
      // Account Kit authorization is distinct from an authenticated cloud session.
      // Do not persist credentials or upload local records before the cloud service is configured.
      this.authorized = true;
      this.message = '华为账号已授权；云同步尚未开通，记录仍保存在本机。';
    } catch (error) {
      const code = (error as BusinessError).code;
      this.message = code === 1001502012 ? '已取消登录' : code === 1001502005 ? '网络连接失败，请稍后重试' : '暂时无法登录，请确认账号服务配置后重试';
    } finally { this.busy = false; }
  }
  logout(): void { this.authorized = false; this.message = ''; }
}
