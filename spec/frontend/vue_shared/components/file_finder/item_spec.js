import Vue, { nextTick } from 'vue';
import createComponent from 'helpers/vue_mount_component_helper';
import { file } from 'jest/ide/helpers';
import ItemComponent from '~/vue_shared/components/file_finder/item.vue';

describe('File finder item spec', () => {
  const Component = Vue.extend(ItemComponent);
  let vm;
  let localFile;

  beforeEach(() => {
    localFile = {
      ...file(),
      name: 'test file',
      path: 'test/file',
    };

    vm = createComponent(Component, {
      file: localFile,
      focused: true,
      searchText: '',
      index: 0,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders file name & path', () => {
    expect(vm.$el.textContent).toContain('test file');
    expect(vm.$el.textContent).toContain('test/file');
  });

  describe('focused', () => {
    it('adds is-focused class', () => {
      expect(vm.$el.classList).toContain('is-focused');
    });

    it('does not have is-focused class when not focused', async () => {
      vm.focused = false;

      await nextTick();
      expect(vm.$el.classList).not.toContain('is-focused');
    });
  });

  describe('changed file icon', () => {
    it('does not render when not a changed or temp file', () => {
      expect(vm.$el.querySelector('.diff-changed-stats')).toBe(null);
    });

    it('renders when a changed file', async () => {
      vm.file.changed = true;

      await nextTick();
      expect(vm.$el.querySelector('.diff-changed-stats')).not.toBe(null);
    });

    it('renders when a temp file', async () => {
      vm.file.tempFile = true;

      await nextTick();
      expect(vm.$el.querySelector('.diff-changed-stats')).not.toBe(null);
    });
  });

  it('emits event when clicked', () => {
    jest.spyOn(vm, '$emit').mockImplementation(() => {});

    vm.$el.click();

    expect(vm.$emit).toHaveBeenCalledWith('click', vm.file);
  });

  describe('path', () => {
    let el;

    beforeEach(async () => {
      vm.searchText = 'file';

      el = vm.$el.querySelector('.diff-changed-file-path');

      nextTick();
    });

    it('highlights text', () => {
      expect(el.querySelectorAll('.highlighted').length).toBe(4);
    });

    it('adds ellipsis to long text', async () => {
      vm.file.path = new Array(70)
        .fill()
        .map((_, i) => `${i}-`)
        .join('');

      await nextTick();
      expect(el.textContent).toBe(`...${vm.file.path.substr(vm.file.path.length - 60)}`);
    });
  });

  describe('name', () => {
    let el;

    beforeEach(async () => {
      vm.searchText = 'file';

      el = vm.$el.querySelector('.diff-changed-file-name');

      await nextTick();
    });

    it('highlights text', () => {
      expect(el.querySelectorAll('.highlighted').length).toBe(4);
    });

    it('does not add ellipsis to long text', async () => {
      vm.file.name = new Array(70)
        .fill()
        .map((_, i) => `${i}-`)
        .join('');

      await nextTick();
      expect(el.textContent).not.toBe(`...${vm.file.name.substr(vm.file.name.length - 60)}`);
    });
  });
});
