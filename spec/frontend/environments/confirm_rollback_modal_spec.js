import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import eventHub from '~/environments/event_hub';

describe('Confirm Rollback Modal Component', () => {
  let environment;

  const envWithLastDeployment = {
    name: 'test',
    last_deployment: {
      commit: {
        short_id: 'abc0123',
      },
    },
    modalId: 'test',
  };

  const envWithoutLastDeployment = {
    name: 'test',
    modalId: 'test',
    commitShortSha: 'abc0123',
    commitUrl: 'test/-/commit/abc0123',
  };

  describe.each`
    hasMultipleCommits | environmentData
    ${true}            | ${envWithLastDeployment}
    ${false}           | ${envWithoutLastDeployment}
  `('when hasMultipleCommits=$hasMultipleCommits', ({ hasMultipleCommits, environmentData }) => {
    beforeEach(() => {
      environment = environmentData;
    });

    it('should show "Rollback" when isLastDeployment is false', () => {
      const component = shallowMount(ConfirmRollbackModal, {
        propsData: {
          environment: {
            ...environment,
            isLastDeployment: false,
          },
          hasMultipleCommits,
        },
      });
      const modal = component.find(GlModal);

      expect(modal.attributes('title')).toContain('Rollback');
      expect(modal.attributes('title')).toContain('test');
      expect(modal.attributes('ok-title')).toBe('Rollback');
      expect(modal.text()).toContain('commit abc0123');
      expect(modal.text()).toContain('Are you sure you want to continue?');
    });

    it('should show "Re-deploy" when isLastDeployment is true', () => {
      const component = shallowMount(ConfirmRollbackModal, {
        propsData: {
          environment: {
            ...environment,
            isLastDeployment: true,
          },
          hasMultipleCommits,
        },
      });
      const modal = component.find(GlModal);

      expect(modal.attributes('title')).toContain('Re-deploy');
      expect(modal.attributes('title')).toContain('test');
      expect(modal.attributes('ok-title')).toBe('Re-deploy');
      expect(modal.text()).toContain('commit abc0123');
      expect(modal.text()).toContain('Are you sure you want to continue?');
    });

    it('should emit the "rollback" event when "ok" is clicked', () => {
      const env = { ...environmentData, isLastDeployment: true };
      const component = shallowMount(ConfirmRollbackModal, {
        propsData: {
          environment: env,
          hasMultipleCommits,
        },
      });
      const eventHubSpy = jest.spyOn(eventHub, '$emit');
      const modal = component.find(GlModal);
      modal.vm.$emit('ok');

      expect(eventHubSpy).toHaveBeenCalledWith('rollbackEnvironment', env);
    });
  });
});
