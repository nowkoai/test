import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import SelectionSummary from 'ee/security_dashboard/components/shared/selection_summary.vue';
import StatusDropdown from 'ee/security_dashboard/components/shared/status_dropdown.vue';
import vulnerabilityStateMutations from 'ee/security_dashboard/graphql/mutate_vulnerability_state';
import eventHub from 'ee/security_dashboard/utils/event_hub';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast');

Vue.use(VueApollo);

describe('Selection Summary component', () => {
  let wrapper;

  const createApolloProvider = (...queries) => {
    return createMockApollo([...queries]);
  };

  const findForm = () => wrapper.find('form');
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findCancelButton = () => wrapper.find('[type="button"]');
  const findSubmitButton = () => wrapper.find('[type="submit"]');
  const isSubmitButtonDisabled = () => findSubmitButton().props('disabled');

  const createComponent = ({ props = {}, apolloProvider } = {}) => {
    wrapper = shallowMount(SelectionSummary, {
      apolloProvider,
      stubs: {
        GlAlert,
      },
      propsData: {
        selectedVulnerabilities: [],
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with 1 vulnerability selected', () => {
    beforeEach(() => {
      createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }] } });
    });

    it('renders correctly', () => {
      expect(findForm().text()).toBe('1 Selected');
    });

    describe('with selected state', () => {
      beforeEach(async () => {
        wrapper.findComponent(StatusDropdown).vm.$emit('change', { action: 'confirm' });
        await nextTick();
      });

      it('displays the submit button when there is s state selected', () => {
        expect(findSubmitButton().exists()).toBe(true);
      });

      it('displays the cancel button when there is s state selected', () => {
        expect(findCancelButton().exists()).toBe(true);
      });
    });

    describe('with no selected state', () => {
      beforeEach(async () => {
        wrapper.findComponent(StatusDropdown).vm.$emit('change', { action: null });
        await nextTick();
      });

      it('does not display the submit button when there is s state selected', () => {
        expect(findSubmitButton().exists()).toBe(false);
      });

      it('does not display the cancel button when there is s state selected', () => {
        expect(findCancelButton().exists()).toBe(false);
      });
    });
  });

  describe('with multiple vulnerabilities selected', () => {
    beforeEach(() => {
      createComponent({ props: { selectedVulnerabilities: [{ id: 'id_0' }, { id: 'id_1' }] } });
    });

    it('renders correctly', () => {
      expect(findForm().text()).toBe('2 Selected');
    });
  });

  describe.each`
    action       | queryName                          | payload           | expected       | successMessage
    ${'dismiss'} | ${'vulnerabilityDismiss'}          | ${undefined}      | ${'dismissed'} | ${'set to dismissed'}
    ${'confirm'} | ${'vulnerabilityConfirm'}          | ${undefined}      | ${'confirmed'} | ${'set to confirmed'}
    ${'resolve'} | ${'vulnerabilityResolve'}          | ${undefined}      | ${'resolved'}  | ${'set to resolved'}
    ${'revert'}  | ${'vulnerabilityRevertToDetected'} | ${'Needs triage'} | ${'detected'}  | ${'set to needs triage'}
  `('state dropdown change', ({ action, queryName, payload, expected, successMessage }) => {
    const selectedVulnerabilities = [
      { id: 'gid://gitlab/Vulnerability/54' },
      { id: 'gid://gitlab/Vulnerability/56' },
      { id: 'gid://gitlab/Vulnerability/58' },
    ];

    const submitForm = async () => {
      wrapper.findComponent(StatusDropdown).vm.$emit('change', { action, payload });
      findForm().trigger('submit');
      await waitForPromises();
    };

    describe('when API call fails', () => {
      beforeEach(() => {
        const apolloProvider = createApolloProvider([
          vulnerabilityStateMutations[action],
          jest.fn().mockRejectedValue({
            data: {
              [queryName]: {
                errors: [
                  {
                    message: 'Something went wrong',
                  },
                ],
              },
            },
          }),
        ]);

        createComponent({ apolloProvider, props: { selectedVulnerabilities } });
      });

      it(`does not emit vulnerability-updated event - ${action}`, async () => {
        await submitForm();
        expect(wrapper.emitted()['vulnerability-updated']).toBeUndefined();
      });

      it(`calls the toaster - ${action}`, async () => {
        await submitForm();
        expect(findGlAlert().text()).toBe(
          'Failed updating vulnerabilities with the following IDs: 54, 56, 58',
        );
      });
    });

    describe('when API call is successful', () => {
      beforeEach(() => {
        const apolloProvider = createApolloProvider([
          vulnerabilityStateMutations[action],
          jest.fn().mockResolvedValue({
            data: {
              [queryName]: {
                errors: [],
                vulnerability: {
                  id: selectedVulnerabilities[0].id,
                  [`${expected}At`]: '2020-09-16T11:13:26Z',
                  state: expected.toUpperCase(),
                },
              },
            },
          }),
        ]);

        createComponent({
          apolloProvider,
          props: { selectedVulnerabilities },
        });
      });

      it(`emits an update for each vulnerability - ${action}`, async () => {
        await submitForm();
        selectedVulnerabilities.forEach((v, i) => {
          expect(wrapper.emitted()['vulnerability-updated'][i][0]).toBe(v.id);
        });
      });

      it(`calls the toaster - ${action}`, async () => {
        await submitForm();
        expect(toast).toHaveBeenLastCalledWith(`3 vulnerabilities ${successMessage}`);
      });

      it(`the submit button is unclickable during form submission - ${action}`, async () => {
        expect(findSubmitButton().exists()).toBe(false);
        submitForm();
        await nextTick();
        expect(isSubmitButtonDisabled()).toBe(true);
        await waitForPromises();
        expect(isSubmitButtonDisabled()).toBe(false);
      });

      it(`emits an event for the event hub - ${action}`, async () => {
        const spy = jest.fn();
        eventHub.$on('vulnerabilities-updated', spy);

        await submitForm();
        expect(spy).toHaveBeenCalled();
      });
    });
  });
});
