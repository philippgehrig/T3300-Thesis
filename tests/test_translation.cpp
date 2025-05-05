#include "gtest/gtest.h"
#include "../translation/pcie_translation.h"

class PCIeTranslationTest : public ::testing::Test {
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
    }
};

TEST_F(PCIeTranslationTest, CanToPcieTranslation) {
    // Create a CAN message
    can_message_t can_msg;
    can_msg.can_id = 0x123;
    can_msg.can_dlc = 8;
    for (int i = 0; i < can_msg.can_dlc; i++) {
        can_msg.data[i] = i;
    }
    can_msg.flags = 0;
    
    // Create a PCIe message to hold the translation result
    pcie_message_t pcie_msg;
    
    // Translate CAN to PCIe
    ASSERT_EQ(translate_can_to_pcie(&can_msg, &pcie_msg, 1, 42), 0);
    
    // Verify the translation
    EXPECT_EQ(pcie_msg.zone_id, 1);
    EXPECT_EQ(pcie_msg.device_id, 42);
    EXPECT_EQ(pcie_msg.message_id, can_msg.can_id);
    EXPECT_EQ(pcie_msg.bus_message.type, MSG_TYPE_CAN);
    EXPECT_EQ(pcie_msg.bus_message.data.can.can_id, can_msg.can_id);
    EXPECT_EQ(pcie_msg.bus_message.data.can.can_dlc, can_msg.can_dlc);
    
    // Check data bytes were copied correctly
    for (int i = 0; i < can_msg.can_dlc; i++) {
        EXPECT_EQ(pcie_msg.bus_message.data.can.data[i], can_msg.data[i]);
    }
}

TEST_F(PCIeTranslationTest, PcieToCan) {
    // Create a PCIe message with CAN data
    pcie_message_t pcie_msg;
    pcie_msg.zone_id = 2;
    pcie_msg.device_id = 33;
    pcie_msg.message_id = 0x456;
    pcie_msg.bus_message.type = MSG_TYPE_CAN;
    pcie_msg.bus_message.data.can.can_id = 0x456;
    pcie_msg.bus_message.data.can.can_dlc = 4;
    for (int i = 0; i < pcie_msg.bus_message.data.can.can_dlc; i++) {
        pcie_msg.bus_message.data.can.data[i] = 10 + i;
    }
    
    // Create a CAN message to hold the translation result
    can_message_t can_msg;
    
    // Translate PCIe to CAN
    ASSERT_EQ(translate_pcie_to_can(&pcie_msg, &can_msg), 0);
    
    // Verify the translation
    EXPECT_EQ(can_msg.can_id, pcie_msg.bus_message.data.can.can_id);
    EXPECT_EQ(can_msg.can_dlc, pcie_msg.bus_message.data.can.can_dlc);
    
    // Check data bytes were copied correctly
    for (int i = 0; i < can_msg.can_dlc; i++) {
        EXPECT_EQ(can_msg.data[i], pcie_msg.bus_message.data.can.data[i]);
    }
}

TEST_F(PCIeTranslationTest, InvalidParameters) {
    // Test with NULL pointers
    pcie_message_t pcie_msg;
    can_message_t can_msg;
    
    EXPECT_EQ(translate_can_to_pcie(NULL, &pcie_msg, 1, 1), -1);
    EXPECT_EQ(translate_can_to_pcie(&can_msg, NULL, 1, 1), -1);
    EXPECT_EQ(translate_pcie_to_can(NULL, &can_msg), -1);
    EXPECT_EQ(translate_pcie_to_can(&pcie_msg, NULL), -1);
    
    // Test with wrong message type
    pcie_msg.bus_message.type = MSG_TYPE_LIN;
    EXPECT_EQ(translate_pcie_to_can(&pcie_msg, &can_msg), -1);
}