////////////////////////////////////////////////////////////////////////////////
/// @brief MVCC transaction id struct
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2014 ArangoDB GmbH, Cologne, Germany
/// Copyright 2004-2014 triAGENS GmbH, Cologne, Germany
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
/// Copyright holder is ArangoDB GmbH, Cologne, Germany
///
/// @author Jan Steemann
/// @author Copyright 2015, ArangoDB GmbH, Cologne, Germany
/// @author Copyright 2011-2013, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#include "TransactionId.h"

using namespace triagens::mvcc;

// -----------------------------------------------------------------------------
// --SECTION--                                               class TransactionId
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                          non-class friend methods
// -----------------------------------------------------------------------------

namespace triagens {
  namespace mvcc {

////////////////////////////////////////////////////////////////////////////////
/// @brief compare two transaction ids
////////////////////////////////////////////////////////////////////////////////

    bool operator== (TransactionId const& lhs,
                     TransactionId const& rhs) {
      return lhs.ownTransactionId == rhs.ownTransactionId;
    }
    
    bool operator== (TransactionId const& lhs,
                     TransactionId::InternalType rhs) {
      return lhs.ownTransactionId == rhs;
    }

    bool operator!= (TransactionId const& lhs,
                     TransactionId const& rhs) {
      return lhs.ownTransactionId != rhs.ownTransactionId;
    }

    bool operator< (TransactionId const& lhs,
                    TransactionId const& rhs) {
      return lhs.ownTransactionId < rhs.ownTransactionId;
    }
  
////////////////////////////////////////////////////////////////////////////////
/// @brief append the transaction id to an output stream
////////////////////////////////////////////////////////////////////////////////

    std::ostream& operator<< (std::ostream& stream,
                              TransactionId const* id) {
      stream << id->toString();
      return stream;
    }
     
    std::ostream& operator<< (std::ostream& stream,
                              TransactionId const& id) {
      stream << id.toString();
      return stream;
    }

  }
}

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// {@inheritDoc}\\|/// @page\\|// --SECTION--\\|/// @\\}"
// End: