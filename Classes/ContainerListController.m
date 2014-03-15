//
//  ContainerListController.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/1/13.
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "ContainerListController.h"
#import "ContainerController.h"
#import "ContainerList.h"


@implementation ContainerListController


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id)init {
	if (self = [super initWithTitle:LocStr(@"CONTAINER_LIST_TITLE") navBarHidden:NO]) {
		m_paths = [ContainerList shared].paths;

		[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(onContainerListDidChange)
			name:kSDKLauncherContainerListDidChange object:nil];
	}

	return self;
}


- (void)loadView {
	self.view = [[UIView alloc] init];

	UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	m_table = table;
	table.dataSource = self;
	table.delegate = self;
	[self.view addSubview:table];
}


- (void)onContainerListDidChange {
	m_paths = [ContainerList shared].paths;
	[m_table reloadData];
}


- (UITableViewCell *)
	tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
		reuseIdentifier:nil];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	NSString *path = [m_paths objectAtIndex:indexPath.row];
	NSArray *components = path.pathComponents;
	cell.textLabel.text = (components == nil || components.count == 0) ?
		@"" : components.lastObject;
	return cell;
}


- (void)
	tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSString *path = [m_paths objectAtIndex:indexPath.row];
	ContainerController *c = [[ContainerController alloc] initWithPath:path];

	if (c != nil) {
		[self.navigationController pushViewController:c animated:YES];
	}
}


- (NSInteger)
	tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
	return m_paths.count;
}


- (void)viewDidLayoutSubviews {
	m_table.frame = self.view.bounds;
}


@end
