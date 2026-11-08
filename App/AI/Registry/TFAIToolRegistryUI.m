#import "TFAIToolRegistryUI.h"
#import "../../DylixI18n.h"
#import "TFAIToolRegistry.h"
#import "../UI/TFAIUIHelpers.h"

@interface TFAIToolRegistrySettings : UITableViewController
@end

@implementation TFAIToolRegistrySettings
- (void)viewDidLoad {
 [super viewDidLoad];
 self.title=DXLoc(@"Agent 功能开关");
 self.tableView.rowHeight=UITableViewAutomaticDimension;
 self.tableView.estimatedRowHeight=68;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
 return 1+([TFAIToolRegistry enabled:@"remote"]||[TFAIToolRegistry enabled:@"isolation"]?1:0);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 if(section==0)return 5;
 return [TFAIToolRegistry enabled:@"remote"]+[TFAIToolRegistry enabled:@"isolation"];
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 return section==0?@"会话能力":DXLoc(@"已开启的扩展");
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
 return section==0?@"关闭后不会向 AI 提供对应工具；已保存的技能、记忆和服务器不会删除。":DXLoc(@"这些扩展不会在此自动开启；关闭后对应工具会从下一轮会话中移除。");
}
- (UITableViewCell *)cell:(NSString *)module title:(NSString *)title detail:(NSString *)detail icon:(NSString *)icon {
 UITableViewCell *cell=AICell(title,detail,icon);
 UISwitch *toggle=[UISwitch new];
 toggle.on=[TFAIToolRegistry enabled:module];
 toggle.accessibilityLabel=title;
 [toggle addAction:[UIAction actionWithHandler:^(UIAction *action){[TFAIToolRegistry setEnabled:toggle.on module:module];[self.tableView reloadData];}] forControlEvents:UIControlEventValueChanged];
 cell.accessoryView=toggle;
 cell.selectionStyle=UITableViewCellSelectionStyleNone;
 return cell;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 if(indexPath.section==0){
  NSArray *modules=@[@"skills",@"memory",@"browser",@"mcp",@"build_queue"];
  NSArray *titles=@[@"技能",DXLoc(@"记忆"),@"浏览器",DXLoc(@"MCP 服务"),@"构建任务"];
  NSArray *details=@[@"按需读取项目技能",DXLoc(@"按需读取本机记忆"),DXLoc(@"让 AI 阅读当前公开网页"),DXLoc(@"已授权的只读查询工具"),DXLoc(@"查看构建队列和进度")];
  NSArray *icons=@[@"text.book.closed",@"brain",@"globe",@"network",@"hammer"];
  NSInteger row=indexPath.row;
  return [self cell:modules[row] title:titles[row] detail:details[row] icon:icons[row]];
 }
 if([TFAIToolRegistry enabled:@"remote"]&&indexPath.row==0)return [self cell:@"remote" title:DXLoc(@"远程工作区状态") detail:DXLoc(@"只返回运行状态") icon:@"wifi"];
 return [self cell:@"isolation" title:DXLoc(@"隔离只读查询") detail:DXLoc(@"当前已开启；关闭后不再提供目标查询") icon:@"lock.shield"];
}
@end

UIViewController *TFAIToolRegistrySettingsController(void){return [[TFAIToolRegistrySettings alloc]initWithStyle:UITableViewStyleInsetGrouped];}
