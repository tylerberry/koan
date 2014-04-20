//
// AutoHyperlinks Framework (c) 2004-2008 by the following:
//
//   Colin Barrett, Graham Booker, Jorge Salvador Caffarena, Evan Schoenberg, Augie Fackler, Stephen Holt, Peter Hosey,
//   Adam Iser, Jeffrey Melloy, Toby Peterson, Eric Richie, David Smith.
//
// License:
//
//   Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
//   following conditions are met:
//
//   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following
//     disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
//     following disclaimer in the documentation and/or other materials provided with the distribution.
//   * Neither the name of the AutoHyperlinks Framework nor the names of its contributors may be used to endorse or
//     promote products derived from this software without specific prior written permission.
//
//   THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
//   EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//   OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
//   TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//   POSSIBILITY OF SUCH DAMAGE.
//
// Modifications by Tyler Berry.
// Copyright (c) 2013 3James Software.
//

typedef enum
{
    AH_URL_INVALID = -1,
    AH_URL_VALID = 0,
    AH_URL_TENTATIVE,
    AH_MAILTO_VALID,
    AH_FILE_VALID,
    AH_URL_DEGENERATE,
    AH_MAILTO_DEGENERATE
} AH_URI_VERIFICATION_STATUS;

typedef struct _AHURLLength
{
  unsigned long urlLength;
  unsigned long schemeLength;
} AHURLLength;

#define YY_EXTRA_TYPE AHURLLength
