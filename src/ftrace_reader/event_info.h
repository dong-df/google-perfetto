/*
 * Copyright (C) 2017 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef SRC_FTRACE_READER_EVENT_PROTO_INFO_H_
#define SRC_FTRACE_READER_EVENT_PROTO_INFO_H_

#include <stdint.h>

#include <string>
#include <vector>

#include "perfetto/base/logging.h"

namespace perfetto {

enum ProtoFieldType {
  kProtoDouble = 1,
  kProtoFloat,
  kProtoInt32,
  kProtoInt64,
  kProtoUint32,
  kProtoUint64,
  kProtoSint32,
  kProtoSint64,
  kProtoFixed32,
  kProtoFixed64,
  kProtoSfixed32,
  kProtoSfixed64,
  kProtoBool,
  kProtoString,
  kProtoBytes,
};

enum FtraceFieldType {
  kFtraceUint32 = 1,
  kFtraceUint64,
  kFtraceChar16,
  kFtraceCString,
};

inline const char* ToString(ProtoFieldType v) {
  switch (v) {
    case kProtoDouble:
      return "double";
    case kProtoFloat:
      return "float";
    case kProtoInt32:
      return "int32";
    case kProtoInt64:
      return "int64";
    case kProtoUint32:
      return "uint32";
    case kProtoUint64:
      return "uint64";
    case kProtoSint32:
      return "sint32";
    case kProtoSint64:
      return "sint64";
    case kProtoFixed32:
      return "fixed32";
    case kProtoFixed64:
      return "fixed64";
    case kProtoSfixed32:
      return "sfixed32";
    case kProtoSfixed64:
      return "sfixed64";
    case kProtoBool:
      return "bool";
    case kProtoString:
      return "string";
    case kProtoBytes:
      return "bytes";
  }
  // For gcc:
  PERFETTO_CHECK(false);
  return "";
}

inline const char* ToString(FtraceFieldType v) {
  switch (v) {
    case kFtraceUint32:
      return "uint32";
    case kFtraceUint64:
      return "uint64";
    case kFtraceChar16:
      return "char[16]";
    case kFtraceCString:
      return "null terminated string";
  }
  // For gcc:
  PERFETTO_CHECK(false);
  return "";
}

struct Field {
  Field() = default;
  Field(uint16_t offset, uint16_t size)
      : ftrace_offset(offset), ftrace_size(size) {}

  uint16_t ftrace_offset;
  uint16_t ftrace_size;
  FtraceFieldType ftrace_type;
  const char* ftrace_name;

  uint32_t proto_field_id;
  ProtoFieldType proto_field_type;
};

struct Event {
  Event() = default;
  Event(const char* event_name, const char* event_group)
      : name(event_name), group(event_group) {}

  const char* name;
  const char* group;
  std::vector<Field> fields;
  uint32_t ftrace_event_id;

  // Field id of the subevent proto (e.g. PrintFtraceEvent) in the FtraceEvent
  // parent proto.
  uint32_t proto_field_id;
};

// The compile time information needed to read the raw ftrace buffer.
// Specifically for each event we have a proto we fill:
//  The event name (e.g. sched_switch)
//  The event group  (e.g. sched)
//  The the proto field ID of this event in the FtraceEvent proto.
//  For each field in the proto:
//    The field name (e.g. prev_comm)
//    The proto field id for this field
//    The proto field type for this field (e.g. kProtoString or kProtoUint32)
// The other fields: ftrace_event_id, ftrace_size, ftrace_offset, ftrace_type
// are zeroed.
std::vector<Event> GetStaticEventInfo();

}  // namespace perfetto

#endif  // SRC_FTRACE_READER_EVENT_PROTO_INFO_H_
