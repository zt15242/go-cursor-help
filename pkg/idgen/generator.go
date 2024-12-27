package idgen

import (
	cryptorand "crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math/big"
	"sync"
)

// Generator handles the generation of various IDs
type Generator struct {
	charsetMu sync.RWMutex
	charset   string
}

// NewGenerator creates a new ID generator with default settings
func NewGenerator() *Generator {
	return &Generator{
		charset: "0123456789ABCDEFGHJKLMNPQRSTVWXYZ",
	}
}

// SetCharset allows customizing the character set used for ID generation
func (g *Generator) SetCharset(charset string) {
	g.charsetMu.Lock()
	defer g.charsetMu.Unlock()
	g.charset = charset
}

// GenerateMachineID generates a new machine ID with the format auth0|user_XX[unique_id]
func (g *Generator) GenerateMachineID() (string, error) {
	prefix := "auth0|user_"

	// Generate random sequence number between 0-99
	seqNum, err := cryptorand.Int(cryptorand.Reader, big.NewInt(100))
	if err != nil {
		return "", fmt.Errorf("failed to generate sequence number: %w", err)
	}
	sequence := fmt.Sprintf("%02d", seqNum.Int64())

	uniqueID, err := g.generateUniqueID(23)
	if err != nil {
		return "", fmt.Errorf("failed to generate unique ID: %w", err)
	}

	fullID := prefix + sequence + uniqueID
	return hex.EncodeToString([]byte(fullID)), nil
}

// GenerateMacMachineID generates a new MAC machine ID using SHA-256
func (g *Generator) GenerateMacMachineID() (string, error) {
	data := make([]byte, 32)
	if _, err := cryptorand.Read(data); err != nil {
		return "", fmt.Errorf("failed to generate random data: %w", err)
	}

	hash := sha256.Sum256(data)
	return hex.EncodeToString(hash[:]), nil
}

// GenerateDeviceID generates a new device ID in UUID v4 format
func (g *Generator) GenerateDeviceID() (string, error) {
	uuid := make([]byte, 16)
	if _, err := cryptorand.Read(uuid); err != nil {
		return "", fmt.Errorf("failed to generate UUID: %w", err)
	}

	// Set version (4) and variant (2) bits according to RFC 4122
	uuid[6] = (uuid[6] & 0x0f) | 0x40
	uuid[8] = (uuid[8] & 0x3f) | 0x80

	return fmt.Sprintf("%x-%x-%x-%x-%x",
		uuid[0:4], uuid[4:6], uuid[6:8], uuid[8:10], uuid[10:16]), nil
}

// generateUniqueID generates a random string of specified length using the configured charset
func (g *Generator) generateUniqueID(length int) (string, error) {
	g.charsetMu.RLock()
	defer g.charsetMu.RUnlock()

	result := make([]byte, length)
	max := big.NewInt(int64(len(g.charset)))

	for i := range result {
		randNum, err := cryptorand.Int(cryptorand.Reader, max)
		if err != nil {
			return "", fmt.Errorf("failed to generate random number: %w", err)
		}
		result[i] = g.charset[randNum.Int64()]
	}

	return string(result), nil
}
