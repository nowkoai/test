import { GlTable, GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import MembersApp from 'ee/pages/groups/saml_providers/saml_members/index.vue';
import createInitialState from 'ee/pages/groups/saml_providers/saml_members/store/state';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';

Vue.use(Vuex);

describe('SAML providers members app', () => {
  let wrapper;
  let fetchPageMock;

  const createWrapper = (state = {}) => {
    const store = new Vuex.Store({
      state: {
        ...createInitialState(),
        ...state,
      },
      actions: {
        fetchPage: fetchPageMock,
      },
    });

    wrapper = shallowMount(MembersApp, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    fetchPageMock = jest.fn();
  });

  describe('on mount', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('dispatches loadPage', () => {
      expect(fetchPageMock).toHaveBeenCalled();
    });

    it('renders loader', () => {
      expect(wrapper.findComponent(GlSkeletonLoading).exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createWrapper({
        isInitialLoadInProgress: false,
      });
    });

    it('does not render loader', () => {
      expect(wrapper.findComponent(GlSkeletonLoading).exists()).toBe(false);
    });

    it('renders table', () => {
      expect(wrapper.findComponent(GlTable).exists()).toBe(true);
    });

    it('requests next page when pagination component performs change', () => {
      const changeFn = wrapper.findComponent(TablePagination).props('change');
      changeFn(2);
      return wrapper.vm.$nextTick(() => {
        expect(fetchPageMock).toHaveBeenCalledWith(expect.anything(), 2);
      });
    });
  });
});
