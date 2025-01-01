package idgen

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"time"
)

// Generator handles secure ID generation for machines and devices
type Generator struct{}

// NewGenerator creates a new ID generator
func NewGenerator() *Generator {
	return &Generator{}
}

// Helper methods
// -------------

// simulateWork adds a small delay to make progress visible
func (g *Generator) simulateWork() {
	time.Sleep(800 * time.Millisecond)
}

// generateRandomHex generates a random hex string of specified length
func (g *Generator) generateRandomHex(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", fmt.Errorf("failed to generate random bytes: %w", err)
	}
	return hex.EncodeToString(bytes), nil
}

// Public methods
// -------------

// GenerateMachineID generates a new machine ID with auth0|user_ prefix
func (g *Generator) GenerateMachineID() (string, error) {
	g.simulateWork()

	// 生成随机部分 (25字节，将产生50个十六进制字符)
	randomPart, err := g.generateRandomHex(25)
	if err != nil {
		return "", err
	}

	// 构建完整的ID: "auth0|user_" + random
	prefix := "auth0|user_"
	fullID := fmt.Sprintf("%x%x%s",
		[]byte(prefix), // 转换前缀为十六进制
		[]byte("0"),    // 添加一个字符
		randomPart,     // 随机部分
	)

	return fullID, nil
}

// GenerateMacMachineID generates a new 64-byte MAC machine ID
func (g *Generator) GenerateMacMachineID() (string, error) {
	g.simulateWork()
	return g.generateRandomHex(64)
}

// GenerateDeviceID generates a new device ID in UUID format
func (g *Generator) GenerateDeviceID() (string, error) {
	g.simulateWork()
	id, err := g.generateRandomHex(16)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%s-%s-%s-%s-%s",
		id[0:8], id[8:12], id[12:16], id[16:20], id[20:32]), nil
}
