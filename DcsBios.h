#ifndef __DCSBIOS_H
#define __DCSBIOS_H

#include "Arduino.h"
#include <Servo.h>

void onDcsBiosWrite(unsigned int address, unsigned int value);
void sendDcsBiosMessage(const char* msg, const char* args);

#define DCSBIOS_STATE_WAIT_FOR_SYNC 0
#define DCSBIOS_STATE_ADDRESS_LOW 1
#define DCSBIOS_STATE_ADDRESS_HIGH 2
#define DCSBIOS_STATE_COUNT_LOW 3
#define DCSBIOS_STATE_COUNT_HIGH 4
#define DCSBIOS_STATE_DATA_LOW 5
#define DCSBIOS_STATE_DATA_HIGH 6

namespace DcsBios {

class ProtocolParser {
	private:
		unsigned char state;
		unsigned int address;
		unsigned int count;
		unsigned int data;
		unsigned char sync_byte_count;
	public:
		void processChar(unsigned char c);
		ProtocolParser();

};

class ExportStreamListener {
	private:
		virtual void onDcsBiosWrite(unsigned int address, unsigned int value) {}
		virtual void onDcsBiosFrameSync() {}
		ExportStreamListener* nextExportStreamListener;
	public:
		static ExportStreamListener* firstExportStreamListener;
		ExportStreamListener() {
			this->nextExportStreamListener = firstExportStreamListener;
			firstExportStreamListener = this;
		}
		static void handleDcsBiosWrite(unsigned int address, unsigned int value) {
			ExportStreamListener* el = firstExportStreamListener;
			while (el) {
				el->onDcsBiosWrite(address, value);
				el = el->nextExportStreamListener;
			}
		}
		static void handleDcsBiosFrameSync() {
			ExportStreamListener* el = firstExportStreamListener;
			while (el) {
				el->onDcsBiosFrameSync();
				el = el->nextExportStreamListener;
			}
		}
};

class PollingInput {
	private:
		virtual void pollInput();
		PollingInput* nextPollingInput;
	public:
		static PollingInput* firstPollingInput;
		PollingInput() {
			this->nextPollingInput = firstPollingInput;
			firstPollingInput = this;
		}
		static void pollInputs() {
			PollingInput* pi = firstPollingInput;
			while (pi) {
				pi->pollInput();
				pi = pi->nextPollingInput;
			}
		}
};

class ActionButton : PollingInput {
	private:
		void pollInput();
		char* msg_;
		char* arg_;
		char pin_;
		char lastState_;
	public:
		ActionButton(char* msg, char* arg, char pin);
};

class Switch2Pos : PollingInput {
	private:
		void pollInput();
		char* msg_;
		char pin_;
		char lastState_;
	public:
		Switch2Pos(char* msg, char pin);
};

class Switch3Pos : PollingInput {
	private:
		void pollInput();
		char* msg_;
		char pinA_;
		char pinB_;
		char lastState_;
		char readState();
	public:
		Switch3Pos(char* msg, char pinA, char pinB);
};

class SwitchMultiPos : PollingInput {
	private:
		void pollInput();
		char* msg_;
		const byte* pins_;
		char numberOfPins_;
		char lastState_;
		char readState();
	public:
		SwitchMultiPos(char* msg_, const byte* pins, char numberOfPins);
};

class Potentiometer : PollingInput {
	private:
		void pollInput();
		char* msg_;
		char pin_;
		unsigned int lastState_;
	public:
		Potentiometer(char* msg, char pin);
};

class RotaryEncoder : PollingInput {
	private:
		void pollInput();
		char readState();
		const char* msg_;
		const char* decArg_;
		const char* incArg_;
		char pinA_;
		char pinB_;
		char lastState_;
		signed char delta_;
	public:
		RotaryEncoder(const char* msg, const char* decArg, const char* incArg, char pinA, char pinB);	
};

class LED : ExportStreamListener {
	private:
		void onDcsBiosWrite(unsigned int address, unsigned int value);
		unsigned char pin_;
		unsigned int address_;
		unsigned int mask_;
	public:
		LED(unsigned int address, unsigned int mask, char pin);
};

class ServoOutput : ExportStreamListener {
	private:
		void onDcsBiosWrite(unsigned int address, unsigned int value);
		Servo servo_;
		unsigned int address_;
		char pin_;
		int minPulseWidth_;
		int maxPulseWidth_;
	public:
		ServoOutput(unsigned int address, char pin, int minPulseWidth, int maxPulseWidth);
		ServoOutput(unsigned int address, char pin) { ServoOutput(address, pin, 544, 2400); }
};

template < unsigned int LENGTH >
class StringBuffer : ExportStreamListener {
	private:
		void onDcsBiosWrite(unsigned int address, unsigned int value) {
			if ((address >= address_) && (address_ + LENGTH > address)) {
				setChar(address - address_, ((char*)&value)[0]);
			if (address_ + LENGTH > (address+1))
				setChar(address - address_ + 1, ((char*)&value)[1]);
			}
		}
		void setChar(unsigned int index, unsigned char value) {
			if (buffer[index] == value) return;
			buffer[index] = value;
			dirty_ = true;
		}
		void onDcsBiosFrameSync() {
			if (dirty_) {
				callback_(buffer);
				dirty_ = false;
			}
		}
		unsigned int address_;
		bool dirty_;
		void (*callback_)(char*);
	public:
		char buffer[LENGTH+1];
		StringBuffer(unsigned int address, void (*callback)(char*)) {
			callback_ = callback;
			dirty_ = false;
			address_ = address;
			memset(buffer, '\0', LENGTH+1);
		}
};



}
#endif















