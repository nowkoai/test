import { DEFAULT_DAYS_TO_DISPLAY } from '../constants';

export default () => ({
  id: null,
  endpoints: {},
  daysInPast: DEFAULT_DAYS_TO_DISPLAY,
  createdAfter: null,
  createdBefore: null,
  stages: [],
  summary: [],
  analytics: [],
  stats: [],
  valueStreams: [],
  selectedValueStream: {},
  selectedStage: {},
  selectedStageEvents: [],
  selectedStageError: '',
  medians: {},
  hasError: false,
  isLoading: false,
  isLoadingStage: false,
  isEmptyStage: false,
  permissions: {},
});
