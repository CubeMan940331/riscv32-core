1. stall_cpu：
	當ddr不可使用時，stall_cpu會拉升到1
2. cache_available:
	當cache被使用但還沒完成所以動作時，會降到0，所以如果cache_available = 0，LSU不應該送新的指令給dcache。
3. interface可能會小修，由於要分離DDR2中，I/D cache的區域，所以如果送給dcache的地址不在dcache使用的範圍，需要執行例外(但這個也可以由LSU檢查，或是dcache自動做地址偏移)
4. 由於DDR2只有128MB，地址太大會超過上限，需檢查(但這個也是可以由LSU去檢查)