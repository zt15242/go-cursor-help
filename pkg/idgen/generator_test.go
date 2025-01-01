package idgen

import (
	"fmt"
	"strings"
	"testing"
)

func TestGenerateMachineID(t *testing.T) {
	g := NewGenerator()

	fmt.Println("\n=== 开始测试 MachineID 生成 ===")

	// 运行多次测试以确保一致性
	for i := 0; i < 10; i++ {
		id, err := g.GenerateMachineID()
		if err != nil {
			t.Fatalf("生成ID时发生错误: %v", err)
		}

		fmt.Printf("\n第 %d 次测试:\n", i+1)
		fmt.Printf("生成的 ID: %s\n", id)
		fmt.Printf("ID 长度: %d\n", len(id))
		fmt.Printf("前缀部分: %s\n", id[:20])
		fmt.Printf("随机部分: %s\n", id[20:])

		// 测试1: 验证总长度
		if len(id) != 74 {
			t.Errorf("ID长度不正确. 期望: 74, 实际: %d", len(id))
		}

		// 测试2: 验证前缀
		expectedPrefix := "61757468307c757365725f" // "auth0|user_" 的十六进制
		if !strings.HasPrefix(id, expectedPrefix) {
			t.Errorf("ID前缀不正确.\n期望前缀: %s\n实际ID: %s", expectedPrefix, id)
		}

		// 测试3: 验证十六进制格式
		for _, c := range id {
			if !strings.ContainsRune("0123456789abcdef", c) {
				t.Errorf("ID包含非十六进制字符: %c", c)
			}
		}
	}

	fmt.Println("\n=== 测试完成 ===")
}
