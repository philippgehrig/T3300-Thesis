#include "gtest/gtest.h"
#include <cstdlib>
#include <string>
#include <thread>
#include <chrono>
#include <mutex>
#include <condition_variable>
#include "../translation/pcie_translation.h"
#include "../pcie/driver/pcie_common.h"
#include "../pcie/driver/pcie_client.h"

// Mock functions to simulate CAN message sending/receiving
extern "C" {
    // Declare these functions as they will be defined in our test harness
    void simulate_can_message_receive(can_message_t *can_msg);
    void simulate_can_message_send(const can_message_t *can_msg);
}

// Test fixture for zonal example tests
class ZonalExampleTest : public ::testing::Test {
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
        
        // Ensure PCIe client is cleaned up
        pcie_client_cleanup();
    }
};

// Mock globals to track calls to our simulation functions
static can_message_t last_received_can_msg;
static can_message_t last_sent_can_msg;
static std::mutex can_mutex;
static std::condition_variable can_cv;
static bool can_message_sent = false;

// Implement our mock functions
void simulate_can_message_receive(can_message_t *can_msg) {
    std::lock_guard<std::mutex> lock(can_mutex);
    can_msg->can_id = 0x123;
    can_msg->can_dlc = 8;
    for (int i = 0; i < can_msg->can_dlc; i++) {
        can_msg->data[i] = i * 2;
    }
    can_msg->flags = 0;
    
    // Copy to our tracking variable
    memcpy(&last_received_can_msg, can_msg, sizeof(can_message_t));
}

void simulate_can_message_send(const can_message_t *can_msg) {
    std::lock_guard<std::mutex> lock(can_mutex);
    memcpy(&last_sent_can_msg, can_msg, sizeof(can_message_t));
    can_message_sent = true;
    can_cv.notify_one();
}

// Test that translates a CAN message, sends it over PCIe, and verifies it's correctly received
TEST_F(ZonalExampleTest, CanMessageTranslationEndToEnd) {
    // Initialize PCIe client
    ASSERT_EQ(pcie_client_init(), 0);
    
    // Create a CAN message
    can_message_t orig_can_msg;
    simulate_can_message_receive(&orig_can_msg);
    
    // Create a bus message
    bus_message_t bus_msg;
    bus_msg.type = MSG_TYPE_CAN;
    bus_msg.timestamp = 0;
    memcpy(&(bus_msg.data.can), &orig_can_msg, sizeof(can_message_t));
    
    // Send it through PCIe
    ASSERT_EQ(pcie_send_bus_message(&bus_msg, 1, 42, 0), 0);
    
    // Create variables to receive the bus message
    bus_message_t received_bus_msg;
    uint32_t source_zone_id;
    uint32_t source_device_id;
    
    // Receive the message
    ASSERT_EQ(pcie_receive_bus_message(&received_bus_msg, &source_zone_id, &source_device_id), 0);
    
    // Verify the message details
    EXPECT_EQ(source_zone_id, 1);
    EXPECT_EQ(source_device_id, 42);
    EXPECT_EQ(received_bus_msg.type, MSG_TYPE_CAN);
    
    // Compare the CAN message data
    EXPECT_EQ(received_bus_msg.data.can.can_id, orig_can_msg.can_id);
    EXPECT_EQ(received_bus_msg.data.can.can_dlc, orig_can_msg.can_dlc);
    for (int i = 0; i < orig_can_msg.can_dlc; i++) {
        EXPECT_EQ(received_bus_msg.data.can.data[i], orig_can_msg.data[i]);
    }
    
    // Now simulate sending this message to a CAN bus
    simulate_can_message_send(&received_bus_msg.data.can);
    
    // Verify the sent message matches the original
    EXPECT_EQ(last_sent_can_msg.can_id, orig_can_msg.can_id);
    EXPECT_EQ(last_sent_can_msg.can_dlc, orig_can_msg.can_dlc);
    for (int i = 0; i < orig_can_msg.can_dlc; i++) {
        EXPECT_EQ(last_sent_can_msg.data[i], orig_can_msg.data[i]);
    }
}

// Test that ensures proper error handling when PCIe client is not initialized
TEST_F(ZonalExampleTest, ErrorHandlingWhenNotInitialized) {
    // Don't initialize PCIe client
    
    // Create a CAN message
    can_message_t can_msg;
    simulate_can_message_receive(&can_msg);
    
    // Create a bus message
    bus_message_t bus_msg;
    bus_msg.type = MSG_TYPE_CAN;
    bus_msg.timestamp = 0;
    memcpy(&(bus_msg.data.can), &can_msg, sizeof(can_message_t));
    
    // Attempt to send it through PCIe (should fail)
    EXPECT_EQ(pcie_send_bus_message(&bus_msg, 1, 42, 0), -1);
}