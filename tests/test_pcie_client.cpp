#include "gtest/gtest.h"
#include "../pcie/driver/pcie_client.h"
#include <string.h>

class PCIeClientTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Set environment variables for testing
        setenv("PCIE_DEVICE_ID", "0000:00:00.0", 1);
        setenv("PCIE_VENDOR_ID", "0x1234", 1);
        setenv("PCIE_SUBSYSTEM_ID", "0x5678", 1);
    }

    void TearDown() override {
        // Clean up environment variables
        unsetenv("PCIE_DEVICE_ID");
        unsetenv("PCIE_VENDOR_ID");
        unsetenv("PCIE_SUBSYSTEM_ID");
        
        // Always clean up the client
        pcie_client_cleanup();
    }
};

TEST_F(PCIeClientTest, Initialization) {
    // Test client initialization
    EXPECT_EQ(pcie_client_init(), 0);
    
    // Test configuration is loaded correctly
    const pcie_config_t* config = pcie_client_get_config();
    ASSERT_NE(config, nullptr);
    EXPECT_STREQ(config->device_id, "0000:00:00.0");
    EXPECT_STREQ(config->vendor_id, "0x1234");
    EXPECT_STREQ(config->subsystem_id, "0x5678");
}

TEST_F(PCIeClientTest, InitializationFailure) {
    // Unset required environment variable
    unsetenv("PCIE_DEVICE_ID");
    
    // Initialization should fail
    EXPECT_EQ(pcie_client_init(), -1);
}

TEST_F(PCIeClientTest, SendMessage) {
    // Initialize client first
    ASSERT_EQ(pcie_client_init(), 0);
    
    // Test successful message sending
    EXPECT_EQ(pcie_client_send("Hello, PCIe!"), 0);
    
    // Test sending NULL message
    EXPECT_EQ(pcie_client_send(NULL), -1);
}

TEST_F(PCIeClientTest, ReceiveMessage) {
    // Initialize client first
    ASSERT_EQ(pcie_client_init(), 0);
    
    char buffer[256];
    
    // Test successful message receiving
    EXPECT_EQ(pcie_client_receive(buffer, sizeof(buffer)), 0);
    
    // Verify message content contains the device ID from config
    EXPECT_TRUE(strstr(buffer, "0000:00:00.0") != NULL);
    
    // Test receiving with NULL buffer
    EXPECT_EQ(pcie_client_receive(NULL, sizeof(buffer)), -1);
    
    // Test receiving with zero buffer size
    EXPECT_EQ(pcie_client_receive(buffer, 0), -1);
}

TEST_F(PCIeClientTest, SendBeforeInit) {
    // Test sending before initialization
    EXPECT_EQ(pcie_client_send("Hello without init"), -1);
}

TEST_F(PCIeClientTest, ReceiveBeforeInit) {
    char buffer[256];
    // Test receiving before initialization
    EXPECT_EQ(pcie_client_receive(buffer, sizeof(buffer)), -1);
}

TEST_F(PCIeClientTest, CleanupAndReinit) {
    // Initialize
    ASSERT_EQ(pcie_client_init(), 0);
    
    // Cleanup
    pcie_client_cleanup();
    
    // Should be able to initialize again
    EXPECT_EQ(pcie_client_init(), 0);
}