"""Generate ordered, uniquely named native chunks from the canonical runtime."""
from pathlib import Path
if __package__:
    from . import build_xmacro_runtime as runtime
else:
    import build_xmacro_runtime as runtime

NATIVE_NAMES = (
    'Native/XM00_Bootstrap.lua', 'Native/XM01_Config.lua',
    'Native/XM02_Registry.lua', 'Native/XM03_Functions.lua',
    'Native/XM04_Core.lua', 'Native/XM05_VanHoa.lua',
    'Native/XM06_Dispatch.lua', 'Native/XM07_KeySpam.lua',
)


def render_native(sources):
    bundle = runtime.render_sources(sources)
    first = bundle.index('-- BEGIN ' + runtime.RUNTIME_MODULES[0])
    header = bundle[:first]
    helpers = header[header.index('local function ReportStartup'):header.index('-- Invalidate old public')]
    helpers = helpers.replace('ReportStartup("Loading Runtime.lua")\n', '')
    expected = ', '.join('["' + name + '"]=false' for name in runtime.RUNTIME_MODULES)
    header = header.replace('modules={}', 'modules={' + expected + '}')
    header = header.replace('Loading Runtime.lua', 'Loading native modules')
    header = header.replace('-- One native entry avoids loader-order and duplicate-basename ambiguity.',
                            '-- Ordered native entries use unique basenames.')
    header += 'runtimeStatus.nativeLayout = "ordered-v1"\nruntimeStatus.nextNative = 1\n'
    chunks = {NATIVE_NAMES[0]: header}
    for index, module in enumerate(runtime.RUNTIME_MODULES, 1):
        start = bundle.index('-- BEGIN ' + module + '\n')
        finish = bundle.index('-- END ' + module + '\n', start) + len('-- END ' + module + '\n')
        text = '-- GENERATED native entry; edit canonical modules, then rebuild.\n'
        text += '''local runtimeStatus = type(xMacro)=="table" and xMacro.Runtime
if type(runtimeStatus)~="table" or runtimeStatus.nativeLayout~="ordered-v1" then
    macro=function() return false end
    error("xMacro native bootstrap missing; combo disabled")
end
'''
        text += ('if runtimeStatus.nextNative ~= ' + str(index) + ' then\n'
                 '    runtimeStatus.ready=false\n'
                 '    macro=function() return false end\n'
                 '    error("xMacro native load order invalid; combo disabled")\nend\n'
                 'runtimeStatus.nextNative = ' + str(index + 1) + '\n')
        text += helpers + bundle[start:finish]
        if index == len(runtime.RUNTIME_MODULES):
            text += bundle[finish:]
        chunks[NATIVE_NAMES[index]] = text
    return chunks


def native_entries():
    return [r'Interface\xMacro' + chr(92) + name.replace('/', chr(92)) for name in NATIVE_NAMES]


def build_native(addon):
    addon = Path(addon)
    runtime.build_runtime(addon)
    sources = {name: (addon / name).read_bytes() for name in runtime.RUNTIME_MODULES}
    for name, text in render_native(sources).items():
        target = addon / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(text.encode('utf-8-sig'))


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--addon', type=Path, required=True)
    build_native(parser.parse_args().addon)
