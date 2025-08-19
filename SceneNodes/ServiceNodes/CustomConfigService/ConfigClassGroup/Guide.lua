local configDesc = {
	{ AttrName = 'Prev', AttrType='string', DefaultValue=''},
	{ AttrName = 'Save', AttrType='bool', DefaultValue=true},
	{ AttrName = 'Type', AttrType='enum', EnumValues='Click,Tips,FightGift'},
	{ AttrName = 'TriggerCondition', AttrType='bool', DefaultValue=false},
	{ AttrName = 'Node', AttrType='string', DefaultValue='', DependAttr='Type', DependAttrValue=0},
	{ AttrName = 'Node2', AttrType='string', DefaultValue='', DependAttr='Type', DependAttrValue=0},
	{ AttrName = 'Diameter', AttrType='double', DefaultValue=50, DependAttr='Type', DependAttrValue=0},
	{ AttrName = 'Tips', AttrType='string', DefaultValue='', DependAttr='Type', DependAttrValue=1},
	{ AttrName = 'Tips2', AttrType='string', DefaultValue='', DependAttr='Type', DependAttrValue=1},
	{ AttrName = 'TipsNode', AttrType='string', DefaultValue='', DependAttr='Type', DependAttrValue=1},
}
return configDesc
