/*
 * This file is part of the libCEC(R) library.
 *
 * libCEC(R) is Copyright (C) 2011-2012 Pulse-Eight Limited.  All rights reserved.
 * libCEC(R) is an original work, containing original code.
 *
 * libCEC(R) is a trademark of Pulse-Eight Limited.
 *
 * This program is dual-licensed; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 *
 * Alternatively, you can license this library under a commercial license,
 * please contact Pulse-Eight Licensing for more information.
 *
 * For more information contact:
 * Pulse-Eight Licensing       <license@pulse-eight.com>
 *     http://www.pulse-eight.com/
 *     http://www.pulse-eight.net/
 */

#include "env.h"
#include "AdapterFactory.h"

#include <stdio.h>
#include "lib/LibCEC.h"
#include "lib/CECProcessor.h"

#if defined(HAVE_P8_USB)
#include "Pulse-Eight/USBCECAdapterDetection.h"
#include "Pulse-Eight/USBCECAdapterCommunication.h"
#endif

#if defined(HAVE_RPI_API)
#include "RPi/RPiCECAdapterDetection.h"
#include "RPi/RPiCECAdapterCommunication.h"
#endif

#if defined(HAVE_TDA995X_API)
#include "CuBox/NxpCECAdapterDetection.h"
#include "CuBox/NxpCECAdapterCommunication.h"
#endif

using namespace std;
using namespace CEC;

int8_t CAdapterFactory::FindAdapters(cec_adapter *deviceList, uint8_t iBufSize, const char *strDevicePath /* = NULL */)
{
  int8_t iAdaptersFound(0);

#if defined(HAVE_P8_USB)
  if (!CUSBCECAdapterDetection::CanAutodetect())
  {
    if (m_lib)
      m_lib->AddLog(CEC_LOG_WARNING, "libCEC has not been compiled with detection code for the Pulse-Eight USB-CEC Adapter, so the path to the COM port has to be provided to libCEC if this adapter is being used");
  }
  else
    iAdaptersFound += CUSBCECAdapterDetection::FindAdapters(deviceList, iBufSize, strDevicePath);
#else
  m_lib->AddLog(CEC_LOG_WARNING, "libCEC has not been compiled with support for the Pulse-Eight USB-CEC Adapter");
#endif

#if defined(HAVE_RPI_API)
  if (iAdaptersFound < iBufSize && CRPiCECAdapterDetection::FindAdapter() &&
      (!strDevicePath || !strcmp(strDevicePath, CEC_RPI_VIRTUAL_COM)))
  {
    snprintf(deviceList[iAdaptersFound].path, 1024, CEC_RPI_VIRTUAL_PATH);
    snprintf(deviceList[iAdaptersFound++].comm, 1024, CEC_RPI_VIRTUAL_COM);
  }
#endif

#if defined(HAVE_TDA995X_API)
  if (iAdaptersFound < iBufSize && CNxpCECAdapterDetection::FindAdapter() &&
      (!strDevicePath || !strcmp(strDevicePath, CEC_TDA995x_VIRTUAL_COM)))
  {
    snprintf(deviceList[iAdaptersFound].path, 1024, CEC_TDA995x_PATH);
    snprintf(deviceList[iAdaptersFound++].comm, 1024, CEC_TDA995x_VIRTUAL_COM);
  }
#endif

#if !defined(HAVE_RPI_API) && !defined(HAVE_P8_USB) && !defined(HAVE_TDA995X_API)
#error "libCEC doesn't have support for any type of adapter. please check your build system or configuration"
#endif

  return iAdaptersFound;
}

IAdapterCommunication *CAdapterFactory::GetInstance(const char *strPort, uint16_t iBaudRate)
{
#if defined(HAVE_TDA995X_API)
  if (!strcmp(strPort, CEC_TDA995x_VIRTUAL_COM))
    return new CNxpCECAdapterCommunication(m_lib->m_cec);
#endif

#if defined(HAVE_RPI_API)
  if (!strcmp(strPort, CEC_RPI_VIRTUAL_COM))
    return new CRPiCECAdapterCommunication(m_lib->m_cec);
#endif

#if defined(HAVE_P8_USB)
  return new CUSBCECAdapterCommunication(m_lib->m_cec, strPort, iBaudRate);
#endif

#if !defined(HAVE_RPI_API) && !defined(HAVE_P8_USB) && !defined(HAVE_TDA995X_API)
  return NULL;
#endif
}

void CAdapterFactory::InitVideoStandalone(void)
{
#if defined(HAVE_RPI_API)
  CRPiCECAdapterCommunication::InitHost();
#endif
}
