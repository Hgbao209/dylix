#import "../Registry/TFAIToolRegistryUI.h"
#import "../../DylixI18n.h"
#import "TFAIAgentUI.h"
#import "../../GitPreferences.h"
#import "TFAIAgentContext.h"
#import "TFAIMCP.h"
#import "TFAIBuildQueue.h"
#import "TFAIReadOnlyBrowser.h"
#import "../UI/TFAIUIHelpers.h"
@interface TFAIAgentText : UIViewController
@property NSString *initial,*root,*expected;
@property BOOL memory;
@property UITextView *text;
@end
@implementation TFAIAgentText
- (void)viewDidLoad{[super viewDidLoad];self.view.backgroundColor=UIColor.systemBackgroundColor;self.text=[[UITextView alloc]initWithFrame:self.view.bounds];self.text.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;self.text.font=[UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];self.text.textContainerInset=UIEdgeInsetsMake(16,12,16,12);self.text.text=self.initial;self.text.editable=self.memory;[self.view addSubview:self.text];if(self.memory)self.navigationItem.rightBarButtonItem=AIBar(@"checkmark",DXLoc(@"保存"),self,@selector(save));}
- (void)save{TMCGitLease *lease __attribute__((objc_precise_lifetime))=[TMCGitLease tryWrite];if(!lease){AIAlert(self,DXLoc(@"项目正在处理"),DXLoc(@"请等待当前文件或Git操作完成后保存。"));return;}NSError *error=nil;if(![TFAIAgentContext saveMemory:self.text.text root:self.root expected:self.expected error:&error]){AIAlert(self,DXLoc(@"记忆未保存"),error.localizedDescription);return;}self.expected=[TFAIAgentContext fingerprint:self.text.text];[self.navigationController popViewControllerAnimated:YES];}
@end
@interface TFAIMCPToolsPage : UITableViewController
@property NSDictionary *server;
@property NSString *sessionID;
@property NSArray *tools;
@property BOOL busy;
@end
@implementation TFAIMCPToolsPage
- (void)viewDidLoad{[super viewDidLoad];self.title=self.server[@"name"];self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=70;self.navigationItem.rightBarButtonItem=AIBar(@"arrow.clockwise",DXLoc(@"发现工具"),self,@selector(discover));[self discover];}
- (void)discover{if(self.busy)return;self.busy=YES;[TFAIMCP.shared discover:self.server[@"id"] completion:^(NSDictionary *result,NSError *error){self.busy=NO;if(error)AIAlert(self,DXLoc(@"MCP发现未完成"),error.localizedDescription);else self.tools=result[@"tools"];[self.tableView reloadData];}];}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t{return 2;}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s{return s?self.tools.count:1;}
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s{return s?@"只读提示属于服务端声明。请只信任你审核过的服务，并逐项开启查询工具；写入、构建和Git工具始终禁用。服务结果是参考数据，不是操作授权。":DXLoc(@"按会话启用；每次App重启后须重新启用并发现工具。服务器和逐项授权保存在本机，鉴权头仅存钥匙串。");}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)i{if(!i.section){UITableViewCell *c=AICell(DXLoc(@"用于当前会话"),self.sessionID.length?@"开关只影响下一轮工具清单":DXLoc(@"请从会话内进入以配置"),@"network");UISwitch *toggle=[UISwitch new];toggle.on=[TFAIMCP.shared enabled:self.server[@"id"] session:self.sessionID];toggle.enabled=self.sessionID.length>0;[toggle addAction:[UIAction actionWithHandler:^(UIAction *a){[TFAIMCP.shared setEnabled:toggle.on server:self.server[@"id"] session:self.sessionID];}] forControlEvents:UIControlEventValueChanged];c.accessoryView=toggle;return c;}NSDictionary *tool=self.tools[i.row];BOOL read=[TFAIMCP readOnlyTool:tool];UITableViewCell *c=AICell(tool[@"name"],read?tool[@"description"]?:@"只读查询":DXLoc(@"写操作或只读声明不足，本期不向AI开放"),read?@"doc.text.magnifyingglass":@"lock");UISwitch *toggle=[UISwitch new];toggle.enabled=read;NSDictionary *current=nil;for(NSDictionary *server in TFAIMCP.shared.servers)if([server[@"id"] isEqual:self.server[@"id"]])current=server;toggle.on=[current[@"allowedTools"] containsObject:tool[@"name"]];[toggle addAction:[UIAction actionWithHandler:^(UIAction *a){NSError *error=nil;if(![TFAIMCP.shared setAllowed:toggle.on tool:tool[@"name"] server:self.server[@"id"] error:&error]){toggle.on=NO;AIAlert(self,DXLoc(@"工具未开启"),error.localizedDescription);}}] forControlEvents:UIControlEventValueChanged];c.accessoryView=toggle;return c;}
@end
@interface TFAIMCPPage : UITableViewController
@property NSString *sessionID;
@property NSArray *servers;
@end
@implementation TFAIMCPPage
- (void)viewDidLoad{[super viewDidLoad];self.title=@"HTTP MCP";self.navigationItem.rightBarButtonItem=AIBar(@"plus",DXLoc(@"导入JSON"),self,@selector(import));self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=70;}
- (void)viewWillAppear:(BOOL)animated{[super viewWillAppear:animated];self.servers=TFAIMCP.shared.servers;[self.tableView reloadData];}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s{return self.servers.count;}
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s{return DXLoc(@"仅Streamable HTTP MCP。不执行command、args、env或服务器脚本。导入后默认关闭；点击服务器发现并审核只读工具，再按会话开启。局域网HTTP为明文传输。");}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)i{NSDictionary *s=self.servers[i.row];UITableViewCell *c=AICell(s[@"name"],s[@"url"],@"network");c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;return c;}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)i{TFAIMCPToolsPage *p=[[TFAIMCPToolsPage alloc]initWithStyle:UITableViewStyleInsetGrouped];p.server=self.servers[i.row];p.sessionID=self.sessionID;[self.navigationController pushViewController:p animated:YES];}
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)i{if(style==UITableViewCellEditingStyleDelete){NSDictionary *server=self.servers[i.row];UIAlertController *a=[UIAlertController alertControllerWithTitle:DXLoc(@"删除服务器与本机鉴权头？") message:server[@"name"] preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];[a addAction:[UIAlertAction actionWithTitle:DXLoc(@"删除") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x){[TFAIMCP.shared remove:server[@"id"]];self.servers=TFAIMCP.shared.servers;[t reloadData];}]];[self presentViewController:a animated:YES completion:nil];}}
- (void)import{TFAIFieldSheet *page=[TFAIFieldSheet new];page.title=DXLoc(@"导入 HTTP MCP");page.hint=DXLoc(@"粘贴mcpServers JSON。仅HTTP(S) URL；headers导入钥匙串。导入后逐项审核工具。");page.value=DXLoc(@"{\"mcpServers\":{\"名称\":{\"url\":\"\"}}}");page.secure=YES;page.save=^(NSString *value){NSError *error=nil;if(![TFAIMCP.shared importJSON:value error:&error])AIAlert(self,DXLoc(@"导入未完成"),error.localizedDescription);else{self.servers=TFAIMCP.shared.servers;[self.tableView reloadData];}};[self presentViewController:[[TMCNavigationController alloc]initWithRootViewController:page] animated:YES completion:nil];}
@end
@interface TFAIAgentSettings : UITableViewController
@property NSString *root,*sessionID;
@property NSArray *skills;
@property(copy) void (^onBrowserAsk)(NSString *url);
@end
@implementation TFAIAgentSettings
- (void)viewDidLoad{[super viewDidLoad];self.title=DXLoc(@"Agent 能力");self.navigationItem.rightBarButtonItem=AIBar(@"switch.2",DXLoc(@"功能开关"),self,@selector(toolSettings));self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=70;}
- (void)toolSettings{[self.navigationController pushViewController:TFAIToolRegistrySettingsController() animated:YES];}
- (void)viewWillAppear:(BOOL)animated{[super viewWillAppear:animated];self.skills=[TFAIAgentContext skills:self.root];[self.tableView reloadData];}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t{return 3;}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s{return s==0?self.skills.count+(self.root.length?1:0):2;}
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s{return @[@"技能",DXLoc(@"记忆与构建"),DXLoc(@"连接与浏览")][s];}
- (NSString *)tableView:(UITableView *)t titleForFooterInSection:(NSInteger)s{return s==0?@"技能正文只在 AI 需要时读取；项目中已有技能不会被覆盖。":s==1?@"记忆保存在本机。关联项目时使用项目 MEMORY.md；未关联时使用通用记忆。":DXLoc(@"浏览器显示真实网页，可将当前页交给 AI；MCP 仅调用你启用的只读工具。");}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)i{NSString *title,*detail,*icon;if(i.section==0){if(i.row==self.skills.count){title=DXLoc(@"安装技能到当前项目");detail=DXLoc(@"保留已有文件");icon=@"plus.square.on.square";}else{NSDictionary *s=self.skills[i.row];title=s[@"name"];detail=[NSString stringWithFormat:@"%@ · %@",[s[@"source"] isEqual:@"builtin"]?@"内置":DXLoc(@"项目"),s[@"description"]];icon=@"text.book.closed";}}else if(i.section==1){title=i.row?@"构建任务":self.root.length?@"项目记忆":DXLoc(@"通用记忆");detail=i.row?@"查看队列和进度":DXLoc(@"编辑 AI 按需读取的本机笔记");icon=i.row?@"hammer":@"brain";}else{title=i.row?@"浏览器":DXLoc(@"MCP 服务");detail=i.row?@"浏览网页，并将当前页交给 AI":DXLoc(@"管理已授权的只读工具");icon=i.row?@"globe":@"network";}UITableViewCell *c=AICell(title,detail,icon);c.accessoryType=UITableViewCellAccessoryDisclosureIndicator;return c;}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)i{[t deselectRowAtIndexPath:i animated:YES];if(i.section==0){if(i.row==self.skills.count){TMCGitLease *lease __attribute__((objc_precise_lifetime))=[TMCGitLease tryWrite];if(!lease){AIAlert(self,DXLoc(@"项目正在处理"),DXLoc(@"请稍后安装技能。"));return;}NSError *error=nil;if(![TFAIAgentContext installSkills:self.root error:&error])AIAlert(self,DXLoc(@"技能安装未完成"),error.localizedDescription);self.skills=[TFAIAgentContext skills:self.root];[t reloadData];return;}NSError *error=nil;NSDictionary *r=[TFAIAgentContext readSkill:self.skills[i.row][@"id"] root:self.root error:&error];if(error){AIAlert(self,DXLoc(@"技能读取失败"),error.localizedDescription);return;}TFAIAgentText *page=[TFAIAgentText new];page.title=self.skills[i.row][@"name"];page.initial=r[@"body"];[self.navigationController pushViewController:page animated:YES];return;}if(i.section==1){if(i.row){[self.navigationController pushViewController:TFAIBuildQueueController() animated:YES];return;}NSError *error=nil;NSString *text=[TFAIAgentContext memory:self.root error:&error];if(!text){AIAlert(self,DXLoc(@"记忆读取失败"),error.localizedDescription);return;}TFAIAgentText *page=[TFAIAgentText new];page.title=self.root.length?@"项目记忆":DXLoc(@"通用记忆");page.root=self.root;page.memory=YES;page.initial=text;page.expected=[TFAIAgentContext fingerprint:text];[self.navigationController pushViewController:page animated:YES];return;}if(i.row)[self.navigationController pushViewController:TFAIReadOnlyBrowserControllerWithAsk(self.sessionID,self.onBrowserAsk) animated:YES];else{TFAIMCPPage *p=[[TFAIMCPPage alloc]initWithStyle:UITableViewStyleInsetGrouped];p.sessionID=self.sessionID;[self.navigationController pushViewController:p animated:YES];}}
@end
UIViewController *TFAIAgentSettingsControllerWithBrowserAction(NSString *root,NSString *session,void (^onAsk)(NSString *url)){TFAIAgentSettings *p=[[TFAIAgentSettings alloc]initWithStyle:UITableViewStyleInsetGrouped];p.root=root;p.sessionID=session;p.onBrowserAsk=onAsk;return p;}
UIViewController *TFAIAgentSettingsController(NSString *root,NSString *session){return TFAIAgentSettingsControllerWithBrowserAction(root,session,nil);}
