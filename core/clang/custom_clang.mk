# Copyright (C) 2015-2019 DragonTC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#################
##  P O L L Y  ##
#################

# Polly flags for use with Clang
POLLY := -O3 \
  -mllvm -polly \
  -mllvm -polly-parallel -lgomp \
  -mllvm -polly-omp-backend=LLVM \
  -mllvm -polly-opt-fusion=max \
  -mllvm -polly-position=after-loopopt \
  -mllvm -polly-run-dce \
  -mllvm -polly-scheduling=dynamic \
  -mllvm -polly-vectorizer=polly \
  -fopenmp -fopenmp-version=50

ifeq ($(my_clang),true)
  # Possible conflicting flags will be filtered out to reduce argument
  # size and to prevent issues with locally set optimizations.
  my_cflags := $(filter-out -Wall -Werror -g -O3 -O2 -Os -O1 -O0 -Og -Oz -Wextra -Weverything,$(my_cflags))
  # Enable -O3 and Polly if not blacklisted, otherwise use -Os.
  my_cflags += $(POLLY) -Qunused-arguments -Wno-unknown-warning-option -w
  my_link_deps += libomp
endif
